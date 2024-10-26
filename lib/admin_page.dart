import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database.dart';
import 'consulta_calendario_page.dart';
import 'admin_add_user_page.dart';

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchCriteria = 'DPI';
  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _filteredPatients = [];
  bool _isAdmin = false; // Variable para verificar si es Administrador

  @override
  void initState() {
    super.initState();
    _checkUserRole(); // Verificar el rol del usuario
    _loadPatients(); // Cargar la lista de pacientes
  }

  // Función para verificar el rol del usuario actual
  Future<void> _checkUserRole() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userEmail = prefs.getString('email');

    if (userEmail != null) {
      Database? db = await DatabaseHelper.instance.database;
      
      // Consultar el rol del usuario usando su correo electrónico
      final List<Map<String, dynamic>> result = await db!.rawQuery('''
        SELECT r.nombre_rol
        FROM ${DatabaseHelper.tableUsuarios} u
        JOIN ${DatabaseHelper.tableRoles} r ON u.id_rol = r.id_rol
        WHERE u.email = ?
      ''', [userEmail]);

      if (result.isNotEmpty) {
        setState(() {
          _isAdmin = result.first['nombre_rol'] == 'Administrador';
        });
      }
    }
  }

  // Función para cargar pacientes desde la base de datos
  Future<void> _loadPatients() async {
    Database? db = await DatabaseHelper.instance.database;

    // Consulta a la base de datos para obtener solo los pacientes
    final List<Map<String, dynamic>> result = await db!.query(
      DatabaseHelper.tableUsuarios,
      where: 'id_rol = (SELECT id_rol FROM ${DatabaseHelper.tableRoles} WHERE nombre_rol = ?)',
      whereArgs: ['Paciente'],
    );

    if (result.isNotEmpty) {
      setState(() {
        _patients = result;
        _filteredPatients = List.from(_patients);
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
        _filteredPatients = List.from(_patients);
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
    await prefs.setBool('isLoggedIn', false);
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Pacientes'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Cerrar sesión',
          ),
          // Mostrar el botón "Agregar Usuarios" solo si el rol es Administrador
          if (_isAdmin) 
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminAddUserPage(),
                  ),
                );
              },
              child: Text('Agregar Usuarios'),
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
                _searchPatient();
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
                          title: Text('${patient['nombre']} ${patient['apellido']}'),
                          subtitle: Text('DPI: ${patient['dpi']} - Correo: ${patient['email']}'),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ConsultaCalendarioPage(
                                  patientId: patient['id_usuario'],
                                  patientName: '${patient['nombre']} ${patient['apellido']}',
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
