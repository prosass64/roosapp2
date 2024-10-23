import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart'; // Para la base de datos
import 'database.dart'; // Importar la clase de la base de datos

class RegisterActivityPage extends StatefulWidget {
  final DateTime selectedDay;
  final int userId; // El ID del usuario actual
  final Function(DateTime, String, List<String>, String) onSave;

  RegisterActivityPage({
    required this.selectedDay,
    required this.userId,
    required this.onSave,
  });

  @override
  _RegisterActivityPageState createState() => _RegisterActivityPageState();
}

class _RegisterActivityPageState extends State<RegisterActivityPage> {
  late String _selectedTreatment;
  late List<String> _selectedSymptoms;
  late TextEditingController _noteController;
  late DateTime _currentDay;

  @override
  void initState() {
    super.initState();
    _currentDay = widget.selectedDay;
    _selectedTreatment = '';
    _selectedSymptoms = [];
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _changeDay(int days) {
    setState(() {
      _currentDay = _currentDay.add(Duration(days: days));
    });
  }

  // Guardar la entrada y los síntomas seleccionados en la base de datos
  Future<void> _saveEntry() async {
    Database? db = await DatabaseHelper.instance.database;

    // Obtener el ID del calendario del usuario
    final List<Map<String, dynamic>> calendarResult = await db!.query(
      DatabaseHelper.tableCalendarios,
      where: 'id_usuario = ?',
      whereArgs: [widget.userId],
    );

    if (calendarResult.isNotEmpty) {
      int idCalendario = calendarResult.first['id_calendario'];

      // Insertar la entrada en la tabla Calendar_Entries
      int entryId = await db.insert(DatabaseHelper.tableCalendarEntries, {
        'id_calendario': idCalendario,
        'fecha': _currentDay.toIso8601String(),
        'id_tratamiento': null, // Se puede añadir lógica de tratamiento si es necesario
        'notas': _noteController.text,
      });

      // Insertar los síntomas seleccionados en la tabla Entry_Symptoms
      for (String symptom in _selectedSymptoms) {
        final List<Map<String, dynamic>> symptomResult = await db.query(
          DatabaseHelper.tableSintomas, // Aquí usamos el nombre de la tabla
          where: 'nombre_sintoma = ?',
          whereArgs: [symptom],
        );

        if (symptomResult.isNotEmpty) {
          int symptomId = symptomResult.first['id_sintoma'];

          await db.insert(DatabaseHelper.tableEntrySymptoms, {
            'id_entrada': entryId,
            'id_sintoma': symptomId,
          });
        }
      }

      // Llamar a la función onSave pasada por el widget
      widget.onSave(
        _currentDay,
        _selectedTreatment,
        _selectedSymptoms,
        _noteController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registrar/Editar Actividad'),
      ),
      body: Column(
        children: [
          // Barra de control de fecha
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  _changeDay(-1); // Retroceder un día
                },
              ),
              Expanded(
                child: Center(
                  child: Text(
                    "${_currentDay.day}/${_currentDay.month}/${_currentDay.year}",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.arrow_forward),
                onPressed: () {
                  _changeDay(1); // Avanzar un día
                },
              ),
            ],
          ),
          // Tratamiento
          DropdownButton<String>(
            value: _selectedTreatment.isEmpty ? null : _selectedTreatment,
            hint: Text('Selecciona un tratamiento'),
            onChanged: (String? newValue) {
              setState(() {
                _selectedTreatment = newValue ?? '';
              });
            },
            items: <String>['Tratamiento A', 'Tratamiento B', 'Tratamiento C']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          // Síntomas
          Expanded(
            child: ListView(
              children: [
                'Dolor de Cabeza',
                'Dolor de Cuerpo',
                'Fatiga',
                'Mareos',
                'Vómitos',
                'Fiebre',
                'Dolor de Estómago',
                'Sangrado',
                'Hinchazón',
                'Caída de Cabello',
                'Dificultad para Respirar'
              ].map((symptom) {
                return CheckboxListTile(
                  title: Text(symptom),
                  value: _selectedSymptoms.contains(symptom),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedSymptoms.add(symptom);
                      } else {
                        _selectedSymptoms.remove(symptom);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          // Nota personalizada
          TextField(
            controller: _noteController,
            decoration: InputDecoration(labelText: 'Añadir una nota'),
          ),
          ElevatedButton(
            onPressed: () {
              _saveEntry(); // Guardar la entrada y los síntomas en la base de datos
              Navigator.pop(context);
            },
            child: Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
