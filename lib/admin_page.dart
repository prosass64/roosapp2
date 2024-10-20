import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'calendar_page.dart';

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}



class _AdminPageState extends State<AdminPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchCriteria = 'DPI';
  List<Map<String, String>> _patients = [];
  List<Map<String, String>> _filteredPatients = [];

  @override
  void initState() {
    super.initState();
    _loadPatients(); // Cargar la lista de pacientes
  }

  // Función para cargar pacientes desde SharedPreferences
  Future<void> _loadPatients() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? storedPatients = prefs.getStringList('patients'); // Guardamos los pacientes en una lista
    if (storedPatients != null) {
      setState(() {
        _patients = storedPatients.map((patient) => Map<String, String>.from(prefs.getString(patient) as Map)).toList();
        _filteredPatients = List.from(_patients); // Inicialmente, mostrar todos los pacientes
      });
    }
  }

  // Función para buscar pacientes
  void _searchPatient() {
    setState(() {
      if (_searchController.text.isEmpty) {
        _filteredPatients = List.from(_patients); // Si no hay búsqueda, mostramos todos
      } else {
        _filteredPatients = _patients.where((patient) {
          final searchText = _searchController.text.toLowerCase();
          if (_searchCriteria == 'DPI') {
            return patient['dpi']!.toLowerCase().contains(searchText);
          } else if (_searchCriteria == 'Nombre') {
            return patient['name']!.toLowerCase().contains(searchText);
          } else if (_searchCriteria == 'Correo') {
            return patient['email']!.toLowerCase().contains(searchText);
          }
          return false;
        }).toList();
      }
    });
  }

  // Función para ver el calendario del paciente seleccionado
  void _viewPatientCalendar(Map<String, String> patient) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CalendarPage(), // Aquí puedes personalizar para cargar el calendario del paciente
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Pacientes'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.pushNamed(context, '/admin_add_user'); // Navegar a la pantalla de agregar usuarios
            },
            tooltip: 'Agregar Administrador o Doctor',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Dropdown para seleccionar el criterio de búsqueda
            DropdownButton<String>(
              value: _searchCriteria,
              onChanged: (String? newValue) {
                setState(() {
                  _searchCriteria = newValue!;
                });
              },
              items: <String>['DPI', 'Nombre', 'Correo']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text('Buscar por $value'),
                );
              }).toList(),
            ),
            // Campo de texto para ingresar el criterio de búsqueda
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Ingrese $_searchCriteria',
              ),
              onChanged: (text) {
                _searchPatient(); // Actualizar la búsqueda en tiempo real
              },
            ),
            SizedBox(height: 20),
            Expanded(
              child: _filteredPatients.isEmpty
                  ? Center(child: Text('No se encontraron pacientes.'))
                  : ListView.builder(
                      itemCount: _filteredPatients.length,
                      itemBuilder: (context, index) {
                        final patient = _filteredPatients[index];
                        return ListTile(
                          title: Text(patient['name'] ?? 'Sin nombre'),
                          subtitle: Text('DPI: ${patient['dpi']} - Correo: ${patient['email']}'),
                          onTap: () {
                            _viewPatientCalendar(patient); // Ver calendario al seleccionar
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
