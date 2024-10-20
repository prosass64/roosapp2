import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminAddUserPage extends StatefulWidget {
  @override
  _AdminAddUserPageState createState() => _AdminAddUserPageState();
}

class _AdminAddUserPageState extends State<AdminAddUserPage> {
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dpiController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'Doctor'; // El administrador podrá elegir entre Doctor o Administrador

  Future<void> _addUser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Verificar si ya hay un usuario registrado con este correo
    final String? storedEmail = prefs.getString('email');
    if (storedEmail == _emailController.text) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Este correo ya está registrado.')));
      return;
    }

    // Registrar nuevo usuario con el rol seleccionado
    await prefs.setString('name', _nameController.text);
    await prefs.setString('lastName', _lastNameController.text);
    await prefs.setString('dpi', _dpiController.text);
    await prefs.setString('email', _emailController.text);
    await prefs.setString('password', _passwordController.text);
    await prefs.setString('role', _selectedRole); // Guardar rol como Doctor o Administrador

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Usuario registrado como $_selectedRole')));
    Navigator.pop(context); // Volver a la página anterior después de registrar
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Agregar Administrador/Doctor')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Nombres'),
            ),
            TextField(
              controller: _lastNameController,
              decoration: InputDecoration(labelText: 'Apellidos'),
            ),
            TextField(
              controller: _dpiController,
              decoration: InputDecoration(labelText: 'No. de DPI'),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Correo electrónico'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
            ),
            DropdownButton<String>(
              value: _selectedRole,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedRole = newValue ?? 'Doctor'; // Doctor será el valor por defecto
                });
              },
              items: <String>['Administrador', 'Doctor']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addUser,
              child: Text('Agregar Usuario'),
            ),
          ],
        ),
      ),
    );
  }
}
