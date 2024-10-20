import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // Para codificar y decodificar los datos como JSON

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dpiController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _register() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Verificar si ya hay un usuario registrado con este correo
    List<String>? patients = prefs.getStringList('patients') ?? [];
    final String? storedEmail = prefs.getString('email');
    
    if (storedEmail == _emailController.text) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Este correo ya está registrado.')));
      return;
    }

    // Registrar nuevo usuario como Paciente
    final patient = {
      'name': _nameController.text,
      'lastName': _lastNameController.text,
      'dpi': _dpiController.text,
      'email': _emailController.text,
      'password': _passwordController.text,
      'role': 'Paciente',
    };

    // Guardar datos del paciente en la lista de pacientes
    patients.add(jsonEncode(patient)); // Codificar los datos del paciente en JSON
    await prefs.setStringList('patients', patients); // Guardar la lista de pacientes

    // Guardar datos de usuario actual
    await prefs.setString('email', patient['email']!);
    await prefs.setString('password', patient['password']!);
    await prefs.setString('role', 'Paciente');

    await prefs.setBool('isLoggedIn', true);
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Registrar Usuario')),
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
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _register,
              child: Text('Registrar'),
            ),
          ],
        ),
      ),
    );
  }
}
