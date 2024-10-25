import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart'; // Para la base de datos
import 'package:shared_preferences/shared_preferences.dart';
import 'database.dart'; // Tu base de datos
import 'consulta_calendario_page.dart'; // Importar la nueva página

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchCriteria = 'DPI';
  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _filteredPatients = [];

  @override
  void initState() {
    super.initState();
    _loadPatients(); // Cargar la lista de pacientes
  }

  // Función para cargar pacientes desde la base de datos
  Future<void> _loadPatients() async {
    Database? db = await DatabaseHelper.instance.database;

    // Consulta a la base de datos para obtener solo los pacientes (usuarios con id_rol correspondiente a "Paciente")
    final List<Map<String, dynamic>> result = await db!.query(
      DatabaseHelper.tableUsuarios,
      where: 'id_rol = (SELECT id_rol FROM ${DatabaseHelper.tableRoles} WHERE nombre_rol = ?)',
      whereArgs: ['Paciente'],
    );

    if (result.isNotEmpty) {
      setState(() {
        _patients = result;
        _filteredPatients = List.from(_patients); // Mostrar todos los pacientes por defecto
      });
    } else {
      setState(() {
        _patients = [];
        _filteredPatients = [];
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
            return patient['dpi']!.toString().toLowerCase().contains(searchText);
          } else if (_searchCriteria == 'Nombre') {
            return patient['nombre']!.toLowerCase().contains(searchText) ||
                   patient['apellido']!.toLowerCase().contains(searchText);
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
                          title: Text('${patient['nombre']} ${patient['apellido']}'), // Mostrar nombre y apellido
                          subtitle: Text('DPI: ${patient['dpi']} - Correo: ${patient['email']}'),
                          onTap: () {
                            // Navegar a la página de consulta calendario al seleccionar un paciente
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ConsultaCalendarioPage(
                                  patientId: patient['id_usuario'], // Pasar el ID del paciente a la nueva página
                                  patientName: '${patient['nombre']} ${patient['apellido']}', // Pasar el nombre completo
                                ),
                              ),
                            );
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
