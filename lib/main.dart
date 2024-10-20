import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'calendar_page.dart';
import 'package:intl/date_symbol_data_local.dart'; // Importar la inicialización de formato de fecha

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null); // Inicializar el formato de fecha para español
  runApp(HematoOncoApp());
}

class HematoOncoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hemato-Oncología',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: FutureBuilder(
        future: _checkLoginStatus(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Center(child: CircularProgressIndicator()), // Pantalla de carga
            );
          } else {
            return snapshot.data == true ? CalendarPage() : LoginPage(); // Navegar a la pantalla adecuada
          }
        },
      ),
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/home': (context) => CalendarPage(),
      },
    );
  }

  Future<bool> _checkLoginStatus() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }
}
