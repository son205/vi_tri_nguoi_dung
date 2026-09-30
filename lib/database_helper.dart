import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(
      databasesPath,
      'location_history.db',
    );

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE location_points (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            timestamp TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> insertLocation({
    required double latitude,
    required double longitude,
    required DateTime timestamp,
  }) async {
    final db = await database;

    return db.insert(
      'location_points',
      {
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': timestamp.toIso8601String(),
      },
    );
  }

  Future<List<Map<String, dynamic>>> getLocations() async {
    final db = await database;

    return db.query(
      'location_points',
      orderBy: 'timestamp ASC',
    );
  }

  Future<void> clearLocations() async {
    final db = await database;

    await db.delete('location_points');
  }
}