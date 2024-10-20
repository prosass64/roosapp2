import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _login() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Verificar credenciales del administrador predefinido
    final String? adminEmail = prefs.getString('adminEmail');
    final String? adminPassword = prefs.getString('adminPassword');
    print('Email ingresado: ${_emailController.text}');
    print('Contraseña ingresada: ${_passwordController.text}');
    print('Administrador registrado: $adminEmail, $adminPassword');

    if (_emailController.text == adminEmail && _passwordController.text == adminPassword) {
      // Login exitoso como Administrador
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('role', 'Administrador'); // Guardar rol de administrador
      Navigator.pushReplacementNamed(context, '/admin');
      return;
    }

    // Verificar credenciales de usuarios almacenados
    final String? storedEmail = prefs.getString('email');
    final String? storedPassword = prefs.getString('password');

    if (_emailController.text == storedEmail && _passwordController.text == storedPassword) {
      // Login exitoso como usuario regular (Paciente)
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('role', 'Paciente');
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      // Mostrar error de credenciales incorrectas
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
              onPressed: _login,
              child: Text('Iniciar Sesión'),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/register'), // Navegar a la pantalla de registro
              child: Text('Registrarse'),
            ),
          ],
        ),
      ),
    );
  }
}
