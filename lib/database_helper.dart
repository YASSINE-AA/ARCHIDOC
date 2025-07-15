import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static const _databaseName = "archidoc.db";
  static const _databaseVersion = 7; // Incremented version

  static const usersTable = 'users';
  static const archivesTable = 'archives';
  static const movementsTable = 'movements';

  static const columnId = 'id';
  static const columnUsername = 'username';
  static const columnPassword = 'password';
  static const columnRole = 'role';

  static const columnColonne = 'colonne';
  static const columnCaisse = 'caisse';
  static const columnDate = 'date';

  static const columnType = 'type';
  static const columnCode = 'code';
  static const columnMovementDate = 'movement_date';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $usersTable (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnUsername TEXT UNIQUE NOT NULL,
        $columnPassword TEXT NOT NULL,
        $columnRole TEXT NOT NULL DEFAULT 'responsable'
      )
    ''');

    await db.execute('''
      CREATE TABLE $archivesTable (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnColonne TEXT NOT NULL,
        $columnCaisse TEXT NOT NULL UNIQUE,
        $columnDate TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $movementsTable (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnType TEXT NOT NULL,
        $columnCode TEXT NOT NULL,
        $columnMovementDate TEXT NOT NULL
      )
    ''');

    // Create admin user
    await db.insert(usersTable, {
      columnUsername: 'admin',
      columnPassword: 'admin123',
      columnRole: 'admin',
    });

    // Create sample responsable user
    await db.insert(usersTable, {
      columnUsername: 'resp',
      columnPassword: 'resp123',
      columnRole: 'responsable',
    });

    // Sample archives
    await db.insert(archivesTable, {
      columnColonne: 'C1',
      columnCaisse: 'BX001',
      columnDate: DateTime.now().toString(),
    });

    await db.insert(archivesTable, {
      columnColonne: 'C2',
      columnCaisse: 'BX002',
      columnDate: DateTime.now().toString(),
    });
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE archives_new (
          $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
          $columnColonne TEXT NOT NULL,
          $columnCaisse TEXT NOT NULL UNIQUE,
          $columnDate TEXT NOT NULL
        )
      ''');

      await db.execute('''
        INSERT INTO archives_new ($columnId, $columnColonne, $columnCaisse, $columnDate)
        SELECT $columnId, $columnColonne, $columnCaisse, '' FROM $archivesTable
      ''');

      await db.execute('DROP TABLE $archivesTable');
      await db.execute('ALTER TABLE archives_new RENAME TO $archivesTable');
    }

    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE $movementsTable (
          $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
          $columnType TEXT NOT NULL,
          $columnCode TEXT NOT NULL,
          $columnMovementDate TEXT NOT NULL
        )
      ''');
    }

    if (oldVersion < 7) {
      await db.execute('''
        ALTER TABLE $usersTable ADD COLUMN $columnRole TEXT NOT NULL DEFAULT 'responsable'
      ''');
      await db.execute('''
        UPDATE $usersTable SET $columnRole = 'admin' WHERE $columnUsername = 'admin'
      ''');
    }
  }

  Future<int> createUser(String username, String password, String role) async {
    final db = await instance.database;
    return await db.insert(usersTable, {
      columnUsername: username,
      columnPassword: password,
      columnRole: role,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getUser(String username) async {
    final db = await instance.database;
    List<Map<String, dynamic>> results = await db.query(
      usersTable,
      where: '$columnUsername = ?',
      whereArgs: [username],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<String?> getUserRole(String username) async {
    final user = await getUser(username);
    return user?[columnRole] as String?;
  }

  Future<int> insertArchive(String colonne, String caisse) async {
    final db = await instance.database;
    return await db.insert(archivesTable, {
      columnColonne: colonne,
      columnCaisse: caisse,
      columnDate: DateTime.now().toString(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getAllArchives() async {
    final db = await instance.database;
    return await db.query(archivesTable);
  }

  Future<List<Map<String, dynamic>>> searchArchives(String query) async {
    final db = await instance.database;
    return await db.query(
      archivesTable,
      where: '$columnColonne LIKE ? OR $columnCaisse LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
  }

  Future<int> updateArchive(int id, String colonne, String caisse) async {
    final db = await instance.database;
    return await db.update(
      archivesTable,
      {
        columnColonne: colonne,
        columnCaisse: caisse,
        columnDate: DateTime.now().toString(),
      },
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteArchive(int id) async {
    final db = await instance.database;
    return await db.delete(
      archivesTable,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertMovement(String type, String code) async {
    final db = await instance.database;
    return await db.insert(movementsTable, {
      columnType: type,
      columnCode: code,
      columnMovementDate: DateTime.now().toString(),
    });
  }

  Future<List<Map<String, dynamic>>> getRecentMovements({int limit = 5}) async {
    final db = await instance.database;
    return await db.query(
      movementsTable,
      orderBy: '$columnMovementDate DESC',
      limit: limit,
    );
  }

  Future<List<Map<String, dynamic>>> getAllMovements() async {
    final db = await instance.database;
    return await db.query(
      movementsTable,
      orderBy: '$columnMovementDate DESC',
    );
  }

  Future<int> purgeArchives() async {
    final db = await instance.database;
    return await db.delete(archivesTable);
  }

  Future<int> purgeMovements() async {
    final db = await instance.database;
    return await db.delete(movementsTable);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}