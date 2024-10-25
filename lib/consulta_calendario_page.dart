import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:sqflite/sqflite.dart';
import 'database.dart'; // Importar la base de datos

class ConsultaCalendarioPage extends StatefulWidget {
  final int patientId;
  final String patientName;

  ConsultaCalendarioPage({required this.patientId, required this.patientName});

  @override
  _ConsultaCalendarioPageState createState() => _ConsultaCalendarioPageState();
}

class _ConsultaCalendarioPageState extends State<ConsultaCalendarioPage> {
  DateTime _selectedDay = DateTime.now();
  Map<DateTime, List<Map<String, dynamic>>> _entriesForDay = {};

  @override
  void initState() {
    super.initState();
    _loadCalendarEntries(); // Cargar las entradas del calendario del paciente
  }

  // Cargar las entradas de calendario del paciente
  Future<void> _loadCalendarEntries() async {
    Database? db = await DatabaseHelper.instance.database;

    // Consulta para obtener las entradas del calendario del paciente
    final List<Map<String, dynamic>> entries = await db!.query(
      DatabaseHelper.tableCalendarEntries,
      where: 'id_calendario = (SELECT id_calendario FROM ${DatabaseHelper.tableCalendarios} WHERE id_usuario = ?)',
      whereArgs: [widget.patientId],
    );

    Map<DateTime, List<Map<String, dynamic>>> newEntriesForDay = {};
    for (var entry in entries) {
      DateTime entryDate = DateTime.parse(entry['fecha']);
      if (newEntriesForDay[entryDate] == null) {
        newEntriesForDay[entryDate] = [];
      }
      newEntriesForDay[entryDate]!.add(entry);
    }

    setState(() {
      _entriesForDay = newEntriesForDay;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calendario de ${widget.patientName}'),
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
            color: Colors.blue, // Color del marcador (puedes personalizarlo)
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRegisteredEntries() {
    final entries = _entriesForDay[_selectedDay] ?? [];

    if (entries.isEmpty) {
      return Center(child: Text('No hay entradas para este día.'));
    }

    return ListView(
      children: entries.map((entry) {
        return ListTile(
          title: Text('Nota: ${entry['notas'] ?? "Sin notas"}'),
        );
      }).toList(),
    );
  }
}
