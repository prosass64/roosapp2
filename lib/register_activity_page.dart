import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart'; // Para la base de datos
//import 'package:dropdown_search/dropdown_search.dart'; // Para el Dropdown con búsqueda
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
  int? _existingEntryId; // Para almacenar si ya existe una entrada
  List<String> _treatments = []; // Lista de tratamientos disponibles

  @override
  void initState() {
    super.initState();
    _currentDay = widget.selectedDay;
    _selectedTreatment = '';
    _selectedSymptoms = [];
    _noteController = TextEditingController();
    _loadExistingEntry(); // Cargar la entrada existente si la hay
    _loadTreatments(); // Cargar los tratamientos disponibles
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // Cargar los tratamientos disponibles desde la base de datos
  Future<void> _loadTreatments() async {
    Database? db = await DatabaseHelper.instance.database;
    
    // Verificar si db no es nulo antes de continuar
    if (db == null) return;

    final List<Map<String, dynamic>> treatmentResults = await db.query(DatabaseHelper.tableTratamientos);

    setState(() {
      _treatments = treatmentResults.map((row) => row['nombre_tratamiento'].toString()).toList();
    });
  }

  void _changeDay(int days) {
    setState(() {
      _currentDay = _currentDay.add(Duration(days: days));
      _loadExistingEntry(); // Cargar la entrada del nuevo día si la hay
    });
  }

  // Cargar una entrada existente si ya hay una en la base de datos para el día seleccionado
  Future<void> _loadExistingEntry() async {
    Database? db = await DatabaseHelper.instance.database;

    // Obtener el ID del calendario del usuario
    final List<Map<String, dynamic>> calendarResult = await db!.query(
      DatabaseHelper.tableCalendarios,
      where: 'id_usuario = ?',
      whereArgs: [widget.userId],
    );

    if (calendarResult.isNotEmpty) {
      int idCalendario = calendarResult.first['id_calendario'];

      // Verificar si ya existe una entrada para el día seleccionado
      final List<Map<String, dynamic>> entryResult = await db.query(
        DatabaseHelper.tableCalendarEntries,
        where: 'id_calendario = ? AND fecha = ?',
        whereArgs: [idCalendario, _currentDay.toIso8601String()],
      );

      if (entryResult.isNotEmpty) {
        setState(() {
          _existingEntryId = entryResult.first['id_entrada']; // Guardar el ID de la entrada existente
          _noteController.text = entryResult.first['notas'] ?? '';
        });

        // Cargar los síntomas seleccionados para la entrada actual
        _loadSelectedSymptoms();
      } else {
        setState(() {
          _existingEntryId = null; // No existe entrada para este día
          _noteController.clear(); // Limpiar los datos
          _selectedSymptoms = []; // Limpiar los síntomas seleccionados
        });
      }
    }
  }

  // Cargar los síntomas seleccionados para la entrada existente
  Future<void> _loadSelectedSymptoms() async {
    if (_existingEntryId == null) return; // Si no hay entrada existente, salir

    Database? db = await DatabaseHelper.instance.database;

    // Verifica si db no es nulo antes de continuar
    if (db == null) return;

    // Obtener los síntomas asociados a la entrada
    final List<Map<String, dynamic>> selectedSymptomsResult = await db.query(
      '${DatabaseHelper.tableEntrySymptoms} es JOIN ${DatabaseHelper.tableSintomas} s ON es.id_sintoma = s.id_sintoma',
      columns: ['s.nombre_sintoma'],
      where: 'es.id_entrada = ?',
      whereArgs: [_existingEntryId],
    );

    setState(() {
      _selectedSymptoms = selectedSymptomsResult.map((symptom) => symptom['nombre_sintoma'].toString()).toList();
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
      int? idTratamiento;

      // Obtener el ID del tratamiento seleccionado (si hay)
      if (_selectedTreatment.isNotEmpty) {
        final List<Map<String, dynamic>> treatmentResult = await db.query(
          DatabaseHelper.tableTratamientos,
          where: 'nombre_tratamiento = ?',
          whereArgs: [_selectedTreatment],
        );
        
        if (treatmentResult.isNotEmpty) {
          idTratamiento = treatmentResult.first['id_tratamiento'];
        }
      }

      if (_existingEntryId != null) {
        // Si ya existe una entrada, actualizarla con el tratamiento
        await db.update(
          DatabaseHelper.tableCalendarEntries,
          {
            'id_tratamiento': idTratamiento, // Asignar el ID del tratamiento (o null)
            'notas': _noteController.text,
          },
          where: 'id_entrada = ?',
          whereArgs: [_existingEntryId],
        );
      } else {
        // Si no existe, crear una nueva entrada
        _existingEntryId = await db.insert(DatabaseHelper.tableCalendarEntries, {
          'id_calendario': idCalendario,
          'fecha': _currentDay.toIso8601String(),
          'id_tratamiento': idTratamiento, // Asignar el ID del tratamiento (o null)
          'notas': _noteController.text,
        });
      }

      // Guardar o actualizar los síntomas
      await db.delete(
        DatabaseHelper.tableEntrySymptoms,
        where: 'id_entrada = ?',
        whereArgs: [_existingEntryId],
      );

      for (String symptom in _selectedSymptoms) {
        final List<Map<String, dynamic>> symptomResult = await db.query(
          DatabaseHelper.tableSintomas,
          where: 'nombre_sintoma = ?',
          whereArgs: [symptom],
        );

        if (symptomResult.isNotEmpty) {
          int symptomId = symptomResult.first['id_sintoma'];

          await db.insert(DatabaseHelper.tableEntrySymptoms, {
            'id_entrada': _existingEntryId,
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
          // Dropdown de tratamientos con búsqueda
          
          DropdownButtonFormField<String>(
            value: _selectedTreatment.isEmpty ? null : _selectedTreatment,
            hint: Text('Selecciona un tratamiento'),
            onChanged: (String? newValue) {
              setState(() {
                _selectedTreatment = newValue ?? '';
              });
            },
            items: [
              DropdownMenuItem<String>(
                value: '', // Representa "Ningún tratamiento"
                child: Text('Ningún tratamiento'),
              ),
              ..._treatments.map((String treatment) {
                return DropdownMenuItem<String>(
                  value: treatment,
                  child: Text(treatment),
                );
              }).toList(),
            ],
            validator: (value) {
              if (value != null && value.isNotEmpty && !_treatments.contains(value)) {
                return 'Por favor, selecciona un tratamiento válido';
              }
              return null;
            },
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

                        // Borrar el síntoma deseleccionado de la tabla Entry_Symptoms
                        _removeSymptomFromDatabase(symptom);
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

  // Función para eliminar un síntoma deseleccionado de la base de datos
  Future<void> _removeSymptomFromDatabase(String symptom) async {
    if (_existingEntryId == null) return;

    Database? db = await DatabaseHelper.instance.database;

    if (db == null) return;

    final List<Map<String, dynamic>> symptomResult = await db.query(
      DatabaseHelper.tableSintomas,
      where: 'nombre_sintoma = ?',
      whereArgs: [symptom],
    );

    if (symptomResult.isNotEmpty) {
      int symptomId = symptomResult.first['id_sintoma'];

      await db.delete(
        DatabaseHelper.tableEntrySymptoms,
        where: 'id_entrada = ? AND id_sintoma = ?',
        whereArgs: [_existingEntryId, symptomId],
      );
    }
  }
}
