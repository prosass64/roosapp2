import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart'; // Para la base de datos
import 'database.dart'; // Nuestra clase de base de datos
import 'calendar_page.dart';

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
  final _confirmPasswordController = TextEditingController(); // Controlador para confirmar contraseña

  final _formKey = GlobalKey<FormState>(); // Clave para el formulario

  // Expresión regular para validar correos electrónicos
  final RegExp emailRegExp = RegExp(r'^[^@]+@[^@]+\.[^@]+$');

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      // Obtener la instancia de la base de datos
      Database? db = await DatabaseHelper.instance.database;

      // Verificar si ya hay un usuario registrado con este correo
      final List<Map<String, dynamic>> result = await db!.query(
        DatabaseHelper.tableUsuarios,
        where: 'email = ?',
        whereArgs: [_emailController.text],
      );

      if (result.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Este correo ya está registrado.')));
        return;
      }

      // Obtener el rol de "Paciente" desde la tabla de Roles
      final List<Map<String, dynamic>> rolesResult = await db.query(
        DatabaseHelper.tableRoles,
        where: 'nombre_rol = ?',
        whereArgs: ['Paciente'],
      );

      if (rolesResult.isNotEmpty) {
        final int idRolPaciente = rolesResult.first['id_rol'];

        // Insertar nuevo usuario con el rol de paciente
        int userId = await db.insert(DatabaseHelper.tableUsuarios, {
          'nombre': _nameController.text,
          'apellido': _lastNameController.text,
          'email': _emailController.text,
          'dpi': _dpiController.text,
          'password': _passwordController.text,
          'id_rol': idRolPaciente, // Asignar rol de Paciente
        });

        // Insertar un nuevo calendario para este usuario
        await db.insert(DatabaseHelper.tableCalendarios, {
          'id_usuario': userId, // Asociar el calendario con el usuario recién creado
        });

        // Guardar estado de sesión (logged in)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('email', _emailController.text); // Guardar el email del usuario

        // Navegar a CalendarPage pasando el correo electrónico del paciente
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CalendarPage(patientEmail: _emailController.text), // Pasar el correo
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: No se pudo asignar el rol de Paciente.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Registrar Usuario')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey, // Formulario clave
          child: Column(
            children: [
              // Nombre
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Nombres'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese su nombre';
                  }
                  return null;
                },
              ),
              // Apellidos
              TextFormField(
                controller: _lastNameController,
                decoration: InputDecoration(labelText: 'Apellidos'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese sus apellidos';
                  }
                  return null;
                },
              ),
              // DPI con teclado numérico
              TextFormField(
                controller: _dpiController,
                decoration: InputDecoration(labelText: 'No. de DPI'),
                keyboardType: TextInputType.number, // Mostrar teclado numérico
                maxLength: 13, // Limitar a 13 dígitos
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese su número de DPI';
                  } else if (value.length != 13) {
                    return 'El DPI debe tener exactamente 13 dígitos';
                  } else if (!RegExp(r'^\d{13}$').hasMatch(value)) {
                    return 'El DPI solo debe contener números';
                  }
                  return null;
                },
              ),
              // Correo electrónico
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Correo electrónico'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese su correo electrónico';
                  } else if (!emailRegExp.hasMatch(value)) {
                    return 'Por favor, ingrese un correo válido';
                  }
                  return null;
                },
              ),
              // Contraseña
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Contraseña'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese su contraseña';
                  } else if (value.length < 6) {
                    return 'La contraseña debe tener al menos 6 caracteres';
                  }
                  return null;
                },
              ),
              // Confirmar contraseña
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(labelText: 'Confirmar Contraseña'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, confirme su contraseña';
                  } else if (value != _passwordController.text) {
                    return 'Las contraseñas no coinciden';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _register,
                child: Text('Registrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
