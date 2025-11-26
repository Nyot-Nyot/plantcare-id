import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/plant_collection.dart';

/// SQLite database helper for managing plant collections locally
/// Follows offline-first strategy from architect.md
class CollectionDatabase {
  static const String _databaseName = 'plantcare.db';
  static const int _databaseVersion = 1;
  static const String _tableName = 'collections';

  // Singleton pattern
  CollectionDatabase._privateConstructor();
  static final CollectionDatabase instance =
      CollectionDatabase._privateConstructor();

  static Database? _database;

  /// Get database instance, initialize if needed
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create tables on first database creation
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT,
        plant_catalog_id TEXT,
        custom_name TEXT NOT NULL,
        scientific_name TEXT,
        image_url TEXT NOT NULL,
        notes TEXT,
        identification_data TEXT,
        created_at TEXT NOT NULL,
        last_cared_at TEXT,
        reminders TEXT,
        confidence REAL,
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Create index for faster queries
    await db.execute('''
      CREATE INDEX idx_user_id ON $_tableName(user_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_created_at ON $_tableName(created_at DESC)
    ''');
  }

  /// Handle database schema upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future schema migrations will go here
    // Example:
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE $_tableName ADD COLUMN new_field TEXT');
    // }
  }

  /// Insert a new plant collection
  Future<int> insert(PlantCollection collection) async {
    final db = await database;
    return await db.insert(
      _tableName,
      collection.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update an existing collection
  Future<int> update(PlantCollection collection) async {
    final db = await database;
    return await db.update(
      _tableName,
      collection.toMap(),
      where: 'id = ?',
      whereArgs: [collection.id],
    );
  }

  /// Delete a collection by ID
  Future<int> delete(int id) async {
    final db = await database;
    return await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  /// Get a single collection by ID
  Future<PlantCollection?> getById(int id) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return PlantCollection.fromMap(maps.first);
  }

  /// Get all collections, optionally filtered by user ID
  Future<List<PlantCollection>> getAll({String? userId}) async {
    final db = await database;

    final maps = await db.query(
      _tableName,
      where: userId != null ? 'user_id = ?' : null,
      whereArgs: userId != null ? [userId] : null,
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => PlantCollection.fromMap(map)).toList();
  }

  /// Get collections that haven't been synced yet
  Future<List<PlantCollection>> getUnsynced({String? userId}) async {
    final db = await database;

    final maps = await db.query(
      _tableName,
      where: userId != null ? 'synced = 0 AND user_id = ?' : 'synced = 0',
      whereArgs: userId != null ? [userId] : null,
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => PlantCollection.fromMap(map)).toList();
  }

  /// Mark a collection as synced
  Future<int> markAsSynced(int id) async {
    final db = await database;
    return await db.update(
      _tableName,
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Update last cared at timestamp
  Future<int> updateLastCaredAt(int id, DateTime timestamp) async {
    final db = await database;
    return await db.update(
      _tableName,
      {'last_cared_at': timestamp.toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Update notes for a collection (efficient single-field update)
  Future<int> updateNotes(int id, String notes) async {
    final db = await database;
    return await db.update(
      _tableName,
      {'notes': notes},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Update custom name for a collection (efficient single-field update)
  Future<int> updateCustomName(int id, String customName) async {
    final db = await database;
    return await db.update(
      _tableName,
      {'custom_name': customName},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Search collections by name (case-insensitive)
  Future<List<PlantCollection>> search(String query, {String? userId}) async {
    final db = await database;

    final maps = await db.query(
      _tableName,
      where: userId != null
          ? '(custom_name LIKE ? OR scientific_name LIKE ?) AND user_id = ?'
          : 'custom_name LIKE ? OR scientific_name LIKE ?',
      whereArgs: userId != null
          ? ['%$query%', '%$query%', userId]
          : ['%$query%', '%$query%'],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => PlantCollection.fromMap(map)).toList();
  }

  /// Get collection count
  Future<int> getCount({String? userId}) async {
    final db = await database;

    final result = await db.rawQuery(
      userId != null
          ? 'SELECT COUNT(*) as count FROM $_tableName WHERE user_id = ?'
          : 'SELECT COUNT(*) as count FROM $_tableName',
      userId != null ? [userId] : null,
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Clear all collections (for testing/development)
  Future<int> deleteAll() async {
    final db = await database;
    return await db.delete(_tableName);
  }

  /// Close database connection
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
