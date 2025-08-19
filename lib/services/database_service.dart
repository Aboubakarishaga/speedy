import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'speed_test.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
    CREATE TABLE speed_tests(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      download_speed REAL NOT NULL,
      upload_speed REAL NOT NULL,
      ping REAL NOT NULL,
      latency REAL NOT NULL,
      ip_address TEXT,
      server_url TEXT,
      test_date TEXT,
      timestamp TEXT,
      unit TEXT NOT NULL,
      latitude REAL,
      longitude REAL,
      location TEXT
    )
  ''');
  }

  Future<int> insertSpeedTest({
    required double downloadSpeed,
    required double uploadSpeed,
    required double ping,
    required double latency,
    String? ipAddress,
    String? serverUrl,
    required String unit,
  }) async {
    final db = await database;
    return await db.insert('speed_tests', {
      'download_speed': downloadSpeed,
      'upload_speed': uploadSpeed,
      'ping': ping,
      'latency': latency,
      'ip_address': ipAddress,
      'server_url': serverUrl,
      'test_date': DateTime.now().toIso8601String(),
      'unit': unit,
    });
  }

  Future<List<Map<String, dynamic>>> getAllSpeedTests() async {
    final db = await database;
    return await db.query(
      'speed_tests',
      orderBy: 'test_date DESC',
    );
  }

  Future<void> deleteSpeedTest(int id) async {
    final db = await database;
    await db.delete(
      'speed_tests',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAllSpeedTests() async {
    final db = await database;
    await db.delete('speed_tests');
  }

  Future<Map<String, dynamic>?> getLatestSpeedTest() async {
    final db = await database;
    final results = await db.query(
      'speed_tests',
      orderBy: 'test_date DESC',
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<List<Map<String, dynamic>>> getSpeedTestsByDateRange(
      DateTime startDate,
      DateTime endDate,
      ) async {
    final db = await database;
    return await db.query(
      'speed_tests',
      where: 'test_date BETWEEN ? AND ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'test_date DESC',
    );
  }
  Future<List<Map<String, dynamic>>> getSpeedTestsWithLocation() async {
    final db = await database;
    return await db.query(
      'speed_tests',
      where: 'latitude IS NOT NULL AND longitude IS NOT NULL',
      orderBy: 'timestamp DESC',
    );
  }

  Future<void> saveSpeedTestWithLocation({
    required double downloadSpeed,
    required double uploadSpeed,
    required double ping,
    required double latency,
    required String unit,
    String? ipAddress,
    double? latitude,
    double? longitude,
    String? location,
  }) async {
    final db = await database;
    await db.insert(
      'speed_tests',
      {
        'download_speed': downloadSpeed,
        'upload_speed': uploadSpeed,
        'ping': ping,
        'latency': latency,
        'unit': unit,
        'ip_address': ipAddress,
        'latitude': latitude,
        'longitude': longitude,
        'location': location,
        'timestamp': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}