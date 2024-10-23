import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'calendar_page.dart'; // Página principal para los pacientes
import 'admin_page.dart'; // Página principal para los administradores
//import 'database.dart'; // Archivo de base de datos
import 'package:intl/date_symbol_data_local.dart'; // Para el formato de fecha

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar formato de fechas
  await initializeDateFormatting('es_ES', null);

  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(HematoOncoApp(isLoggedIn: isLoggedIn));
}

class HematoOncoApp extends StatelessWidget {
  final bool isLoggedIn;

  HematoOncoApp({required this.isLoggedIn});


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hemato-Oncología',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: isLoggedIn ? CalendarPage(patientEmail: 'test@test.com') : LoginPage(),
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/home': (context) => CalendarPage(patientEmail: 'test@test.com'),
        '/admin': (context) => AdminPage(), // Página del administrador
      },
    );
  }
}
