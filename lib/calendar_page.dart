import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database.dart';
import 'register_activity_page.dart';

class CalendarPage extends StatefulWidget {
  final String patientEmail;

  CalendarPage({required this.patientEmail});

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _selectedDay = DateTime.now();
  Map<DateTime, List<Map<String, dynamic>>> _entriesForDay = {}; // Mapa para almacenar las entradas del calendario
  int? _patientId;

  @override
  void initState() {
    super.initState();
    _loadPatientData(); // Cargar los datos del paciente al iniciar
  }

  // Cargar los datos del paciente actual
  Future<void> _loadPatientData() async {
    Database? db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> result = await db!.query(
      DatabaseHelper.tableUsuarios,
      where: 'email = ?', // Usar email u otro identificador
      whereArgs: [widget.patientEmail], // El correo electrónico del usuario actual
    );

    if (result.isNotEmpty) {
      setState(() {
        _patientId = result.first['id_usuario']; // Asignar el id del usuario
      });
      _loadCalendarEntries(); // Cargar las entradas de calendario para el paciente
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: No se encontró el usuario con ese correo')),
      );
    }
  }

  // Cargar las entradas de calendario del paciente
  Future<void> _loadCalendarEntries() async {
    if (_patientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cargar el ID del paciente')));
      return;
    }

    Database? db = await DatabaseHelper.instance.database;

    // Query para obtener entradas de calendario con tratamientos y contar síntomas
    final List<Map<String, dynamic>> entries = await db!.rawQuery('''
      SELECT e.*, 
             (SELECT COUNT(*) FROM ${DatabaseHelper.tableEntrySymptoms} es WHERE es.id_entrada = e.id_entrada) AS symptoms_count,
             t.nombre_tratamiento AS treatment_name
      FROM ${DatabaseHelper.tableCalendarEntries} e
      LEFT JOIN ${DatabaseHelper.tableTratamientos} t ON e.id_tratamiento = t.id_tratamiento
      WHERE e.id_calendario = (SELECT id_calendario FROM ${DatabaseHelper.tableCalendarios} WHERE id_usuario = ?)
    ''', [_patientId]);

    // Filtrar los días que no tienen síntomas, tratamientos ni notas
    Map<DateTime, List<Map<String, dynamic>>> newEntriesForDay = {};
    for (var entry in entries) {
      bool hasSymptoms = entry['symptoms_count'] != null && entry['symptoms_count'] > 0;
      bool hasTreatment = entry['treatment_name'] != null && entry['treatment_name'].isNotEmpty;
      bool hasNotes = entry['notas'] != null && entry['notas'].isNotEmpty;

      // Solo incluir días que tengan al menos un síntoma, tratamiento o nota
      if (hasSymptoms || hasTreatment || hasNotes) {
        DateTime entryDate = DateTime.parse(entry['fecha']);
        if (newEntriesForDay[entryDate] == null) {
          newEntriesForDay[entryDate] = [];
        }
        newEntriesForDay[entryDate]!.add(entry);
      }
    }

    setState(() {
      _entriesForDay = newEntriesForDay;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calendario del Paciente'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout, // Botón para cerrar sesión
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            locale: 'es_ES', 
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _selectedDay,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
              });
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, focusedDay) {
                if (_entriesForDay[day] != null) {
                  return _buildMarkers(_entriesForDay[day]!);
                }
                return null;
              },
            ),
          ),
          SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: () {
              if (_patientId != null) {
                Navigator.push<dynamic>(
                  context,
                  MaterialPageRoute<dynamic>(
                    builder: (BuildContext context) => RegisterActivityPage(
                      selectedDay: _selectedDay,
                      userId: _patientId!, // Pasar el id_usuario al siguiente widget
                      onSave: (DateTime day, String treatment, List<String> symptoms, String customNote) {
                        setState(() {
                          if (_entriesForDay[day] == null) {
                            _entriesForDay[day] = <Map<String, dynamic>>[];
                          }
                          _entriesForDay[day]!.add(<String, dynamic>{
                            'treatment': treatment,
                            'symptoms': symptoms,
                            'customNote': customNote,
                          });
                        });

                        _loadCalendarEntries(); // Recargar entradas
                      },
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ID del paciente no encontrado.'),
                  ),
                );
              }
            },
            child: Text('Registrar/Editar Actividad'),
          ),
          SizedBox(height: 16.0),
          Expanded(
            child: _buildRegisteredEntries(),
          ),
        ],
      ),
    );
  }

  // Construir los marcadores para las fechas que tienen entradas
  // Construir los marcadores para las fechas que tienen entradas
Widget _buildMarkers(List<Map<String, dynamic>> entries) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: entries.expand((entry) {
      List<Widget> markers = [];

      bool hasSymptoms = entry['symptoms_count'] != null && entry['symptoms_count'] > 0;
      bool hasTreatment = entry['treatment_name'] != null && entry['treatment_name'].isNotEmpty;
      bool hasNotes = entry['notas'] != null && entry['notas'].isNotEmpty;

      // Si hay notas, agregar un marcador negro
      if (hasNotes) {
        markers.add(_buildSingleMarker(Colors.black));
      }

      // Si hay síntomas, agregar un marcador naranja
      if (hasSymptoms) {
        markers.add(_buildSingleMarker(Colors.orange));
      }

      // Si hay tratamiento, agregar un marcador azul
      if (hasTreatment) {
        markers.add(_buildSingleMarker(Colors.blue));
      }

      return markers;
    }).toList(), // Expandimos la lista de marcadores para cada tipo
  );
}

// Función auxiliar para construir un solo marcador
Widget _buildSingleMarker(Color color) {
  return Container(
    margin: EdgeInsets.symmetric(horizontal: 2.0),
    width: 8.0,
    height: 8.0,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color,
    ),
  );
}


  // Construir la lista de entradas registradas
  Widget _buildRegisteredEntries() {
    final entries = _entriesForDay[_selectedDay] ?? [];

    if (entries.isEmpty) {
      return Center(child: Text('No hay entradas para este día.'));
    }

    return ListView(
      children: entries.map((entry) {
        return ListTile(
          title: Text('Nota: ${entry['notas']}'),
        );
      }).toList(),
    );
  }

  // Función para cerrar sesión
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    Navigator.pushReplacementNamed(context, '/login');
  }
}
