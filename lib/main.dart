import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Para la localización
import 'package:table_calendar/table_calendar.dart';
//import 'package:intl/intl.dart'; // Manejo de fechas y localización

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // Para codificar/decodificar los datos como JSON


void main() {
  runApp(HematoOncoApp());
}

class HematoOncoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hemato-Oncología',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('es', ''), // Español
      ],
      home: CalendarPage(),
    );
  }
}

class CalendarPage extends StatefulWidget {
  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _selectedDay = DateTime.now();
  Map<DateTime, Map<String, dynamic>> _patientData = {};

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  // Cargar los datos almacenados localmente
  Future<void> _loadPatientData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? patientDataJson = prefs.getString('patientData');
    
    if (patientDataJson != null) {
      setState(() {
        Map<String, dynamic> decodedData = jsonDecode(patientDataJson);
        _patientData = decodedData.map((key, value) => MapEntry(DateTime.parse(key), value));
      });
    }
  }

  // Guardar los datos en almacenamiento local
  Future<void> _savePatientData() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(
      _patientData.map((key, value) => MapEntry(key.toIso8601String(), value)),
    );
    await prefs.setString('patientData', encodedData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registro de Tratamientos y Síntomas'),
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
              markerBuilder: (context, day, events) {
                if (_patientData[day] != null) {
                  List<Widget> markers = [];

                  if (_patientData[day]?['symptoms'] != null && (_patientData[day]?['symptoms'] as List).isNotEmpty) {
                    markers.add(_buildMarker(Colors.orange));
                  }
                  if (_patientData[day]?['treatment'] != null && _patientData[day]?['treatment'] != '') {
                    markers.add(_buildMarker(Colors.blue));
                  }
                  if (_patientData[day]?['customNote'] != null && _patientData[day]?['customNote'] != '') {
                    markers.add(_buildMarker(Colors.black));
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: markers,
                  );
                }
                return null;
              },
            ),
          ),
          SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RegisterActivityPage(
                    selectedDay: _selectedDay,
                    patientData: _patientData, // Asegúrate de pasar _patientData aquí
                    onSave: (day, treatment, symptoms, customNote) {
                      setState(() {
                        _patientData[day] = {
                          'treatment': treatment,
                          'symptoms': symptoms,
                          'customNote': customNote,
                        };
                      });
                      _savePatientData();
                    },
                  ),
                ),
              );
            },
            child: Text('Registrar/Editar Actividad'),
          ),
          SizedBox(height: 16.0),
          Expanded(
            child: _buildRegisteredData(),
          ),
        ],
      ),
    );
  }

  Widget _buildMarker(Color color) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 1.0),
      width: 8.0,
      height: 8.0,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }

  Widget _buildRegisteredData() {
    if (_patientData[_selectedDay] != null) {
      return ListView(
        children: [
          ListTile(
            title: Text('Tratamiento registrado:'),
            subtitle: Text(_patientData[_selectedDay]?['treatment'] ?? 'Ninguno'),
          ),
          ListTile(
            title: Text('Síntomas registrados:'),
            subtitle: Text((_patientData[_selectedDay]?['symptoms']?.cast<String>()?.join(', ') ?? '')),
          ),
          ListTile(
            title: Text('Nota personalizada:'),
            subtitle: Text(_patientData[_selectedDay]?['customNote'] ?? 'Sin notas'),
          ),
        ],
      );
    } else {
      return Center(
        child: Text('No hay datos registrados para este día.'),
      );
    }
  }
}

class RegisterActivityPage extends StatefulWidget {
  final DateTime selectedDay;
  final Map<DateTime, Map<String, dynamic>> patientData; // Añadir este parámetro
  final Function(DateTime, String, List<String>, String) onSave;

  RegisterActivityPage({
    required this.selectedDay,
    required this.patientData, // Añadir este parámetro
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
    _loadDataForCurrentDay(); // Cargar los datos del día actual
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
              children: ['Dolor de Cabeza', 'Dolor de Cuerpo', 'Fatiga', 'Mareos', 'Vomitos', 'Fiebre', 'Dolor de estomago', 'Dolor de cabeza', 'Sangrado', 'Hinchazón', 'Caída de cabello', 'Dificultad para respirar']
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