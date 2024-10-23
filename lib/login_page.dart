import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart'; // Para la base de datos
import 'database.dart'; // Nuestra clase de base de datos
import 'calendar_page.dart';//Calendario

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _login() async {
    // Obtener la instancia de la base de datos
    Database? db = await DatabaseHelper.instance.database;

    // Consultar si existe el usuario con las credenciales
    final List<Map<String, dynamic>> result = await db!.query(
      DatabaseHelper.tableUsuarios,
      where: 'email = ? AND password = ?',
      whereArgs: [_emailController.text, _passwordController.text],
    );

    if (result.isNotEmpty) {
      // Login exitoso, guardar estado de sesión (logged in)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('email', _emailController.text); // Guardar email en SharedPreferences

      // Navegar a CalendarPage pasando el correo electrónico del paciente
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CalendarPage(patientEmail: _emailController.text), // Pasar el correo
        ),
      );
    } else {
      // Mostrar error de credenciales inválidas
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Credenciales inválidas')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Iniciar Sesión')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
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
              onPressed: _login, // Llamar a la función de login
              child: Text('Iniciar Sesión'),
            ),
          ],
        ),
      ),
    );
  }
}
