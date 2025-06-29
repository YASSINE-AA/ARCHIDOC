import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static const _databaseName = "archidoc.db";
  static const _databaseVersion = 1;

  // Table names
  static const usersTable = 'users';
  static const archivesTable = 'archives';

  // Users table columns
  static const columnId = 'id';
  static const columnUsername = 'username';
  static const columnPassword = 'password';

  // Archives table columns
  static const columnRangee = 'rangee';
  static const columnColonne = 'colonne';
  static const columnCaisse = 'caisse';

  // Singleton pattern
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize the database
  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  // Create tables
  Future _onCreate(Database db, int version) async {
    // Users table for authentication
    await db.execute('''
      CREATE TABLE $usersTable (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnUsername TEXT UNIQUE NOT NULL,
        $columnPassword TEXT NOT NULL
      )
    ''');

    // Archives table for storage
    await db.execute('''
      CREATE TABLE $archivesTable (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnRangee TEXT NOT NULL,
        $columnColonne TEXT NOT NULL,
        $columnCaisse TEXT NOT NULL UNIQUE
      )
    ''');

    // Insert default admin user
    await db.insert(usersTable, {
      columnUsername: 'admin',
      columnPassword: 'admin123', // In production, use hashed passwords
    });

    // Insert sample archives
    await db.insert(archivesTable, {
      columnRangee: 'A1',
      columnColonne: 'C1',
      columnCaisse: 'BX001',
    });
    await db.insert(archivesTable, {
      columnRangee: 'A1',
      columnColonne: 'C2',
      columnCaisse: 'BX002',
    });
  }

  // ========== USERS TABLE OPERATIONS ==========

  Future<int> createUser(String username, String password) async {
    Database db = await instance.database;
    return await db.insert(usersTable, {
      columnUsername: username,
      columnPassword: password,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map?> getUser(String username) async {
    Database db = await instance.database;
    List<Map> results = await db.query(
      usersTable,
      where: '$columnUsername = ?',
      whereArgs: [username],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  // ========== ARCHIVES TABLE OPERATIONS ==========
  Future<int> insertArchive(
    String rangee,
    String colonne,
    String caisse,
  ) async {
    Database db = await instance.database;
    return await db.insert(archivesTable, {
      columnRangee: rangee,
      columnColonne: colonne,
      columnCaisse: caisse,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getAllArchives() async {
    Database db = await instance.database;
    return await db.query(archivesTable);
  }

  Future<List<Map<String, dynamic>>> searchArchives(String query) async {
    Database db = await instance.database;
    return await db.query(
      archivesTable,
      where:
          '$columnRangee LIKE ? OR $columnColonne LIKE ? OR $columnCaisse LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
    );
  }

  Future<int> updateArchive(
    int id,
    String rangee,
    String colonne,
    String caisse,
  ) async {
    Database db = await instance.database;
    return await db.update(
      archivesTable,
      {columnRangee: rangee, columnColonne: colonne, columnCaisse: caisse},
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteArchive(int id) async {
    Database db = await instance.database;
    return await db.delete(
      archivesTable,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  // Close the database connection
  Future close() async {
    Database db = await instance.database;
    db.close();
  }
}
