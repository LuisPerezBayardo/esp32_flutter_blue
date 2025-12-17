import 'package:esp32_bluetooth_plus/screens/detail_device/detailDevice.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'screens/detail_user/detailUser.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'users.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE,
            password TEXT,
            type TEXT,
            privileges TEXT
          )
        ''');
        // Tabla DEVICES (nueva) también en onCreate para instalaciones nuevas
        await _createDevicesTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Migraciones incrementales
        if (oldVersion < 2) {
          await _createDevicesTable(db);
        }
      },
    );
  }


  Future<Usuario?> getUserById(int id) async {
    final db = await database;
    final rows = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    /*final result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );*/
    if (rows.isNotEmpty) {
      return Usuario.fromMap(rows.first); // ✅ aquí conviertes
    }
    return null;
  }

  Future<int> insertUser(String name, String password, String type) async {
    final db = await database;
    String privileges = "user2 privileges; ";
    if(type == "user1") privileges += "user1 privileges; ";
    if(type == "admin") privileges += "admin privileges; ";
    return await db.insert('users', {
      'name': name,
      'password': password,
      'type': type,
      'privileges': privileges
    });
  }

  Future<bool> validateUser(int id, String password) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'id = ? AND password = ?',
      whereArgs: [id, password],
    );
    return result.isNotEmpty;
  }

  Future<bool> userExists(String id) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty;
  }


  Future<int> updateUser(int id, String name, String password, String type) async {
    final db = await database;

    // Generar los privilegios según el tipo
    String privileges = "user2 privileges; ";
    if (type == "user1") privileges += "user1 privileges; ";
    if (type == "admin") privileges += "admin privileges; ";

    // Actualizar el usuario con los nuevos datos
    return await db.update(
      'users',
      {
        'name': name,
        'password': password,
        'type': type,
        'privileges': privileges,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }


  Future<void> resetDB() async {
    final path = join(await getDatabasesPath(), 'users.db');
    await deleteDatabase(path);
    print(">>> Base de datos borrada en: $path");
    _db = null; // para que se vuelva a inicializar con _initDB
  }






  ////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///
  ///       DEVICE
  /// 
  ///



  Future<void> _createDevicesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS devices(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        address TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        rssi INTEGER,
        last_seen INTEGER,
        favorite INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        serial TEXT,
        functionType TEXT,
        deviceType TEXT,
        privilegeType TEXT
      )
    ''');     // AJUSTAR CAMPOS
    await db.execute('CREATE INDEX IF NOT EXISTS idx_devices_address ON devices(address)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_devices_favorite ON devices(favorite)');
  }



  Future<Dispositivo?> getDeviceById(int id) async {
    final db = await database;
    final rows = await db.query(
      'devices',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    /*final result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );*/
    if (rows.isNotEmpty) {
      return Dispositivo.fromMap(rows.first); // ✅ aquí conviertes
    }
    return null;
  }



  /// Inserta un dispositivo (fallará si ya existe el address por UNIQUE).
  Future<int> insertDevice(String address, String name, int rssi, bool last_seen, int favorite, String notes,
                                                        String serial, String functionType, String deviceType, String privilegeType) async {
    final db = await database;
    return await db.insert('devices', {
      //'id': id,
      'address': address,
      'name': name,
      'rssi': rssi,
      'last_seen': last_seen,
      'favorite': favorite,
      'notes': notes,
      'serial': serial,
      'functionType': functionType,
      'deviceType': deviceType,
      'privilegeType': privilegeType
    });
  }


  Future<bool> validateDevice(int id, String address) async {
    final db = await database;
    final result = await db.query(
      'devices',
      where: 'id = ? AND address = ?',
      whereArgs: [id, address],
    );
    return result.isNotEmpty;
  }


  Future<bool> deviceExists(String id) async {
    final db = await database;
    final result = await db.query(
      'device',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty;
  }


  Future<int> updateDevice(int id, String address, String name, String rssi, bool last_seen, int favorite, String notes,
                                                        String serial, String functionType, String deviceType, String privilegeType) async {
    final db = await database;
    return await db.update(
      'devices', {
        'id': id,
        'address': address,
        'name': name,
        'rssi': rssi,
        'last_seen': last_seen,
        'favorite': favorite,
        'notes': notes,
        'serial': serial,
        'functionType': functionType,
        'deviceType': deviceType,
        'privilegeType': privilegeType
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

}

