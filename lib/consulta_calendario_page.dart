import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:sqflite/sqflite.dart';
import 'database.dart'; // Importar la base de datos

class ConsultaCalendarioPage extends StatefulWidget {
  final int patientId; // Recibimos el ID del paciente
  final String patientName; // Recibimos el nombre del paciente

  ConsultaCalendarioPage({required this.patientId, required this.patientName});

  @override
  _ConsultaCalendarioPageState createState() => _ConsultaCalendarioPageState();
}

class _ConsultaCalendarioPageState extends State<ConsultaCalendarioPage> {
  DateTime _selectedDay = DateTime.now();
  Map<DateTime, List<Map<String, dynamic>>> _entriesForDay = {}; // Mapa para almacenar las entradas del calendario

  @override
  void initState() {
    super.initState();
    _loadCalendarEntries(); // Cargar las entradas del calendario del paciente
  }

  // Cargar las entradas de calendario del paciente
  Future<void> _loadCalendarEntries() async {
    Database? db = await DatabaseHelper.instance.database;

    // Query para obtener entradas de calendario con tratamientos y contar síntomas
    final List<Map<String, dynamic>> entries = await db!.rawQuery('''
      SELECT e.*, 
             (SELECT COUNT(*) FROM ${DatabaseHelper.tableEntrySymptoms} es WHERE es.id_entrada = e.id_entrada) AS symptoms_count,
             t.nombre_tratamiento AS treatment_name
      FROM ${DatabaseHelper.tableCalendarEntries} e
      LEFT JOIN ${DatabaseHelper.tableTratamientos} t ON e.id_tratamiento = t.id_tratamiento
      WHERE e.id_calendario = (SELECT id_calendario FROM ${DatabaseHelper.tableCalendarios} WHERE id_usuario = ?)
    ''', [widget.patientId]);

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
        title: Text('Calendario de ${widget.patientName}'), // Mostramos el nombre del paciente
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

  // Construir la lista de entradas registradas (incluyendo notas, síntomas y tratamientos)
  Widget _buildRegisteredEntries() {
    final entries = _entriesForDay[_selectedDay] ?? [];

    if (entries.isEmpty) {
      return Center(child: Text('No hay entradas para este día.', style: TextStyle(fontSize: 16.0, fontStyle: FontStyle.italic)));
    }

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      children: entries.map((entry) {
        // Obtener detalles de notas, síntomas y tratamientos
        final String notes = entry['notas'] != null && entry['notas'].isNotEmpty ? entry['notas'] : 'Sin notas';
        final String treatment = entry['treatment_name'] != null && entry['treatment_name'].isNotEmpty ? entry['treatment_name'] : 'Sin tratamiento';

        // Cargar los síntomas asociados a la entrada
        final int entryId = entry['id_entrada'];
        return FutureBuilder<List<String>>(
          future: _loadSymptomsForEntry(entryId), // Cargar los síntomas para esta entrada
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ); // Mostrar un indicador de carga mientras se obtienen los síntomas
            }

            final List<String> symptoms = snapshot.data ?? [];
            final String symptomsText = symptoms.isNotEmpty ? symptoms.join(', ') : 'Sin síntomas';

            // Mostrar los detalles con formato
            return Card(
              elevation: 3.0,
              margin: EdgeInsets.symmetric(vertical: 8.0),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título de la entrada (con íconos)
                    Row(
                      children: [
                        Icon(Icons.notes, color: Colors.black54),
                        SizedBox(width: 8.0),
                        Text('Notas:', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 32.0, top: 4.0, bottom: 8.0),
                      child: Text(notes, style: TextStyle(fontSize: 14.0, color: Colors.black87)),
                    ),

                    // Tratamiento
                    Row(
                      children: [
                        Icon(Icons.medical_services, color: Colors.blue),
                        SizedBox(width: 8.0),
                        Text('Tratamiento:', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 32.0, top: 4.0, bottom: 8.0),
                      child: Text(treatment, style: TextStyle(fontSize: 14.0, color: Colors.black87)),
                    ),

                    // Síntomas
                    Row(
                      children: [
                        Icon(Icons.sick, color: Colors.orange),
                        SizedBox(width: 8.0),
                        Text('Síntomas:', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 32.0, top: 4.0, bottom: 8.0),
                      child: Text(symptomsText, style: TextStyle(fontSize: 14.0, color: Colors.black87)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  // Función para cargar los síntomas asociados a una entrada
  Future<List<String>> _loadSymptomsForEntry(int entryId) async {
    Database? db = await DatabaseHelper.instance.database;

    // Consultar los síntomas asociados a esta entrada
    final List<Map<String, dynamic>> result = await db!.rawQuery('''
      SELECT s.nombre_sintoma
      FROM ${DatabaseHelper.tableEntrySymptoms} es
      JOIN ${DatabaseHelper.tableSintomas} s ON es.id_sintoma = s.id_sintoma
      WHERE es.id_entrada = ?
    ''', [entryId]);

    // Devolver una lista con los nombres de los síntomas
    return result.map((row) => row['nombre_sintoma'] as String).toList();
  }
}
