import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'color_data.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE colors (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            imagePath TEXT,
            predictedPH REAL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {},
    );
  }

  Future<int> savePredictedPH(String imagePath, double predictedPH) async {
    final db = await database;
    return await db.insert(
      'colors',
      {
        'imagePath': imagePath,
        'predictedPH': predictedPH,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<double>> fetchPredictedPHValues() async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query('colors');
    return results
        .map((row) => double.tryParse(row['predictedPH'].toString()) ?? 0.0)
        .toList();
  }

  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('colors');
  }
}
