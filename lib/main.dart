import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'calendar_page.dart';
import 'admin_page.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'admin_add_user_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null);
  await _createDefaultAdmin(); // Crear un administrador predefinido
  runApp(HematoOncoApp());
}

Future<void> _createDefaultAdmin() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  // Verificar si ya existe un administrador
  final String? storedEmail = prefs.getString('adminEmail');
  if (storedEmail == null) {
    // Si no existe, crear uno
    await prefs.setString('adminEmail', 'admin@clinica.com');
    await prefs.setString('adminPassword', 'admin123');
    await prefs.setString('adminRole', 'Administrador');

    // Verificar que el administrador se ha guardado correctamente
    print('Administrador creado: admin@clinica.com, admin123');
  } else {
    print('Administrador ya existe: $storedEmail');
  }
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
              body: Center(child: CircularProgressIndicator()),
            );
          } else {
            if (snapshot.hasData && snapshot.data != null) {
              final role = snapshot.data as String;
              return role == 'Administrador' ? AdminPage() : CalendarPage();
            } else {
              return LoginPage();
            }
          }
        },
      ),
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/home': (context) => CalendarPage(),
        '/admin': (context) => AdminPage(),
        '/admin_add_user': (context) => AdminAddUserPage(),
      },
    );
  }

  Future<String?> _checkLoginStatus() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('isLoggedIn') ?? false) {
      return prefs.getString('role'); // Retorna el rol del usuario
    }
    return null;
  }
}
