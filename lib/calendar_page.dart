import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database.dart';
import 'register_activity_page.dart';

class CalendarPage extends StatefulWidget {
  final String patientEmail; // Email del paciente logueado

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

  // Obtener el ID del usuario basado en el correo electrónico (o cualquier otro identificador único)
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
    // Si no se encuentra el paciente, mostrar un error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: No se encontró el usuario con ese correo')),
    );
  }
}



  // Cargar las entradas de calendario del paciente
  Future<void> _loadCalendarEntries() async {
    if (_patientId == null) {
      // Muestra un error o no permite registrar actividades si el ID no se ha cargado correctamente
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cargar el ID del paciente')));
      return;
    }

    Database? db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> entries = await db!.query(
      DatabaseHelper.tableCalendarEntries,
      where: 'id_calendario = (SELECT id_calendario FROM Calendarios WHERE id_usuario = ?)',
      whereArgs: [_patientId],
    );

    Map<DateTime, List<Map<String, dynamic>>> newEntriesForDay = {};
    for (var entry in entries) {
      DateTime entryDate = DateTime.parse(entry['fecha']);
      if (newEntriesForDay[entryDate] == null) {
        newEntriesForDay[entryDate] = [];
      }
      newEntriesForDay[entryDate]!.add(entry); // Añadir las entradas al mapa
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
            locale: 'es_ES', // Configurar el idioma a español
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
                          // Actualizar los datos de la entrada en la UI
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
                // Muestra un error si el patientId es nulo
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ID del paciente no encontrado.'),
                  ),
                );
              }
            },
            child: Text('Registrar/Editar Actividad'), // Esto define lo que se muestra en el botón
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
  Widget _buildMarkers(List<Map<String, dynamic>> entries) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: entries.map((entry) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 2.0),
          width: 8.0,
          height: 8.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue, // Puedes cambiar el color según el tipo de entrada
          ),
        );
      }).toList(),
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
    await prefs.setBool('isLoggedIn', false); // Eliminar el estado de inicio de sesión
    Navigator.pushReplacementNamed(context, '/login'); // Redirigir a la pantalla de inicio de sesión
  }
}
