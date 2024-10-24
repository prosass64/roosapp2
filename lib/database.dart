import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final _databaseName = "clinic_db.db";
  static final _databaseVersion = 1;

  // Tablas
  static final tableUsuarios = 'Usuarios';
  static final tableRoles = 'Roles'; // Tabla para roles
  static final tableCalendarios = 'Calendarios';
  static final tableCalendarEntries = 'Calendar_Entries';
  static final tableTratamientos = 'Tratamientos';
  static final tableSintomas = 'Sintomas';
  static final tableEntrySymptoms = 'Entry_Symptoms';

  // Singleton
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database?> get database async {
    if (_database != null) return _database;
    _database = await _initDatabase();
    return _database;
  }

  // Inicializar la base de datos
  _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(path, version: _databaseVersion, onCreate: _onCreate);
  }

  // Crear las tablas y datos iniciales
  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableRoles (
        id_rol INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre_rol VARCHAR(50) NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableUsuarios (
        id_usuario INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre VARCHAR(100) NOT NULL,
        apellido VARCHAR(100) NOT NULL,
        email VARCHAR(255) NOT NULL UNIQUE,
        dpi VARCHAR(13) NOT NULL UNIQUE,
        password VARCHAR(255) NOT NULL,
        id_rol INTEGER NOT NULL,
        FOREIGN KEY (id_rol) REFERENCES $tableRoles(id_rol)
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableCalendarios (
        id_calendario INTEGER PRIMARY KEY AUTOINCREMENT,
        id_usuario INTEGER NOT NULL,
        FOREIGN KEY (id_usuario) REFERENCES $tableUsuarios(id_usuario)
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableCalendarEntries (
        id_entrada INTEGER PRIMARY KEY AUTOINCREMENT,
        id_calendario INTEGER NOT NULL,
        id_tratamiento INTEGER,
        fecha DATE NOT NULL,
        notas TEXT,
        FOREIGN KEY (id_calendario) REFERENCES $tableCalendarios(id_calendario),
        FOREIGN KEY (id_tratamiento) REFERENCES $tableTratamientos(id_tratamiento)
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableTratamientos (
        id_tratamiento INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre_tratamiento VARCHAR(100) NOT NULL,
        descripcion TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableSintomas (
        id_sintoma INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre_sintoma VARCHAR(100) NOT NULL,
        descripcion TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableEntrySymptoms (
        id_sintoma INTEGER NOT NULL,
        id_entrada INTEGER NOT NULL,
        FOREIGN KEY (id_sintoma) REFERENCES $tableSintomas(id_sintoma),
        FOREIGN KEY (id_entrada) REFERENCES $tableCalendarEntries(id_entrada),
        PRIMARY KEY (id_sintoma, id_entrada)
      )
    ''');

    // Insertar los roles iniciales
    await db.insert(tableRoles, {'nombre_rol': 'Administrador'});
    await db.insert(tableRoles, {'nombre_rol': 'Doctor'});
    await db.insert(tableRoles, {'nombre_rol': 'Paciente'});

    // Obtener los roles de Administrador, Doctor y Paciente
    final List<Map<String, dynamic>> rolesResultAdmin = await db.query(
      tableRoles,
      where: 'nombre_rol = ?',
      whereArgs: ['Administrador'],
    );
    final int idRolAdmin = rolesResultAdmin.first['id_rol'];

    final List<Map<String, dynamic>> rolesResultDoctor = await db.query(
      tableRoles,
      where: 'nombre_rol = ?',
      whereArgs: ['Doctor'],
    );
    final int idRolDoctor = rolesResultDoctor.first['id_rol'];

    final List<Map<String, dynamic>> rolesResultPaciente = await db.query(
      tableRoles,
      where: 'nombre_rol = ?',
      whereArgs: ['Paciente'],
    );
    final int idRolPaciente = rolesResultPaciente.first['id_rol'];

    // Insertar un usuario predeterminado como administrador
    await db.insert(tableUsuarios, {
      'nombre': 'Admin',
      'apellido': 'Principal',
      'email': 'admin@admin.com',
      'dpi': '1234567890123',
      'password': 'admin123', // Contraseña por defecto
      'id_rol': idRolAdmin,  // Asignar el rol de Administrador
    });

    // Insertar un usuario predeterminado como doctor
    await db.insert(tableUsuarios, {
      'nombre': 'Doctor',
      'apellido': 'Pruebas',
      'email': 'doctor@clinic.com',
      'dpi': '2345678901234',
      'password': 'doctor123', // Contraseña para pruebas
      'id_rol': idRolDoctor,  // Asignar el rol de Doctor
    });

    // Insertar un usuario predeterminado como paciente
    await db.insert(tableUsuarios, {
      'nombre': 'Paciente',
      'apellido': 'Pruebas',
      'email': 'paciente@clinic.com',
      'dpi': '3456789012345',
      'password': 'paciente123', // Contraseña para pruebas
      'id_rol': idRolPaciente,  // Asignar el rol de Paciente
    });

    // Insertar un calendario para el paciente de prueba
    await db.insert(tableCalendarios, {
      'id_usuario': (await db.query(tableUsuarios, where: 'email = ?', whereArgs: ['paciente@clinic.com'])).first['id_usuario'],
    });

    await db.insert(tableSintomas, {'nombre_sintoma': 'Dolor de Cabeza', 'descripcion': 'Sensación de dolor en la cabeza o parte superior del cuello.'});
    await db.insert(tableSintomas, {'nombre_sintoma': 'Dolor de Cuerpo', 'descripcion': 'Malestar o dolor generalizado en los músculos o articulaciones.'});
    await db.insert(tableSintomas, {'nombre_sintoma': 'Fatiga', 'descripcion': 'Sensación de cansancio extremo o falta de energía.'});
    await db.insert(tableSintomas, {'nombre_sintoma': 'Mareos', 'descripcion': 'Sensación de inestabilidad o de que todo gira a tu alrededor.'});
    await db.insert(tableSintomas, {'nombre_sintoma': 'Vómitos', 'descripcion': 'Expulsión forzada del contenido del estómago a través de la boca.'});
    await db.insert(tableSintomas, {'nombre_sintoma': 'Fiebre', 'descripcion': 'Aumento temporal de la temperatura corporal.'});
    await db.insert(tableSintomas, {'nombre_sintoma': 'Dolor de Estómago', 'descripcion': 'Dolor o malestar en la parte abdominal.'});
    await db.insert(tableSintomas, {'nombre_sintoma': 'Sangrado', 'descripcion': 'Pérdida de sangre por una lesión o causa interna.'});
    await db.insert(tableSintomas, {'nombre_sintoma': 'Hinchazón', 'descripcion': 'Aumento de volumen en una parte del cuerpo debido a una acumulación de líquido.'});
    await db.insert(tableSintomas, {'nombre_sintoma': 'Caída de Cabello', 'descripcion': 'Pérdida excesiva o anormal de cabello.'});
    await db.insert(tableSintomas, {'nombre_sintoma': 'Dificultad para Respirar', 'descripcion': 'Problemas para inhalar suficiente aire o sentir falta de aire.'});

  }
}
