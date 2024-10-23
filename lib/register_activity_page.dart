import 'package:flutter/material.dart';

class RegisterActivityPage extends StatefulWidget {
  final DateTime selectedDay;
  final Map<DateTime, Map<String, dynamic>> patientData;
  final Function(DateTime, String, List<String>, String) onSave;

  RegisterActivityPage({
    required this.selectedDay,
    required this.patientData,
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
    _loadDataForCurrentDay(); // Cargar los datos del día actual si existen
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _changeDay(int days) {
    setState(() {
      _currentDay = _currentDay.add(Duration(days: days));
      _loadDataForCurrentDay(); // Cargar los datos del nuevo día
    });
  }

  void _loadDataForCurrentDay() {
    final patientData = widget.patientData[_currentDay] ?? {};
    setState(() {
      _selectedTreatment = patientData['treatment'] ?? '';
      _selectedSymptoms = List<String>.from(patientData['symptoms'] ?? []);
      _noteController.text = patientData['customNote'] ?? '';
    });
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
              children: ['Dolor de Cabeza', 'Dolor de Cuerpo', 'Fatiga', 'Mareos', 'Vómitos', 'Fiebre', 'Dolor de estómago', 'Sangrado', 'Hinchazón', 'Caída de cabello', 'Dificultad para respirar']
                  .map((symptom) => CheckboxListTile(
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
                      ))
                  .toList(),
            ),
          ),
          // Nota personalizada
          TextField(
            controller: _noteController,
            decoration: InputDecoration(labelText: 'Añadir una nota'),
          ),
          ElevatedButton(
            onPressed: () {
              widget.onSave(
                _currentDay,
                _selectedTreatment,
                _selectedSymptoms,
                _noteController.text,
              );
              Navigator.pop(context);
            },
            child: Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
