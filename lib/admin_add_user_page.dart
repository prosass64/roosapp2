import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
//import 'package:shared_preferences/shared_preferences.dart';
import 'database.dart';

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
  final _confirmPasswordController = TextEditingController();
  String _selectedRole = 'Doctor';
  final _formKey = GlobalKey<FormState>();

  final RegExp emailRegExp = RegExp(r'^[^@]+@[^@]+\.[^@]+$');

  Future<void> _addUser() async {
    if (_formKey.currentState!.validate()) {
      Database? db = await DatabaseHelper.instance.database;

      // Verificar si el correo ya existe
      final List<Map<String, dynamic>> result = await db!.query(
        DatabaseHelper.tableUsuarios,
        where: 'email = ?',
        whereArgs: [_emailController.text],
      );

      if (result.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Este correo ya está registrado.')));
        return;
      }

      // Obtener el rol seleccionado desde la base de datos
      final List<Map<String, dynamic>> rolesResult = await db.query(
        DatabaseHelper.tableRoles,
        where: 'nombre_rol = ?',
        whereArgs: [_selectedRole],
      );

      if (rolesResult.isNotEmpty) {
        final int roleId = rolesResult.first['id_rol'];

        // Insertar nuevo usuario con el rol seleccionado
        await db.insert(DatabaseHelper.tableUsuarios, {
          'nombre': _nameController.text,
          'apellido': _lastNameController.text,
          'email': _emailController.text,
          'dpi': _dpiController.text,
          'password': _passwordController.text,
          'id_rol': roleId,
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Usuario registrado como $_selectedRole')));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: No se pudo asignar el rol.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Agregar Administrador/Doctor')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Nombres'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese el nombre';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _lastNameController,
                decoration: InputDecoration(labelText: 'Apellidos'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese los apellidos';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _dpiController,
                decoration: InputDecoration(labelText: 'No. de DPI'),
                keyboardType: TextInputType.number,
                maxLength: 13,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese el DPI';
                  } else if (value.length != 13) {
                    return 'El DPI debe tener exactamente 13 dígitos';
                  } else if (!RegExp(r'^\d{13}$').hasMatch(value)) {
                    return 'El DPI solo debe contener números';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Correo electrónico'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese el correo electrónico';
                  } else if (!emailRegExp.hasMatch(value)) {
                    return 'Ingrese un correo válido';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Contraseña'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese la contraseña';
                  } else if (value.length < 6) {
                    return 'La contraseña debe tener al menos 6 caracteres';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(labelText: 'Confirmar Contraseña'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, confirme la contraseña';
                  } else if (value != _passwordController.text) {
                    return 'Las contraseñas no coinciden';
                  }
                  return null;
                },
              ),
              DropdownButton<String>(
                value: _selectedRole,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedRole = newValue ?? 'Doctor';
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
      ),
    );
  }
}
