import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
    List<String>? storedPatients = prefs.getStringList('patients'); // Obtener la lista de pacientes
    if (storedPatients != null) {
      setState(() {
        _patients = storedPatients
            .map((patient) => Map<String, String>.from(jsonDecode(patient)))
            .toList();
        _filteredPatients = List.from(_patients); // Mostrar todos los pacientes por defecto
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

  // Función para cerrar sesión
  Future<void> _logout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false); // Eliminar el estado de inicio de sesión
    Navigator.pushReplacementNamed(context, '/login'); // Volver a la pantalla de inicio de sesión
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Pacientes'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout, // Botón para cerrar sesión
            tooltip: 'Cerrar sesión',
          ),
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
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Ingrese $_searchCriteria del paciente',
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
