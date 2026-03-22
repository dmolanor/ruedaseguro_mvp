import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:hive/hive.dart';

class LocalStorageService {
  Database? _db;
  Box? _prefsBox;

  Future<void> init() async {
    // SQLite for offline cache
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dbPath, 'ruedaseguro_cache.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE cached_profiles (
            id TEXT PRIMARY KEY,
            data TEXT NOT NULL,
            cached_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE cached_vehicles (
            id TEXT PRIMARY KEY,
            data TEXT NOT NULL,
            cached_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE cached_policies (
            id TEXT PRIMARY KEY,
            data TEXT NOT NULL,
            cached_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE cached_exchange_rates (
            id TEXT PRIMARY KEY,
            data TEXT NOT NULL,
            cached_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE pending_sync_queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            table_name TEXT NOT NULL,
            operation TEXT NOT NULL,
            payload TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            retries INTEGER DEFAULT 0
          )
        ''');
      },
    );

    // Hive for simple key-value storage
    _prefsBox = await Hive.openBox('preferences');
  }

  Database get db {
    if (_db == null) throw StateError('LocalStorageService not initialized');
    return _db!;
  }

  // Key-value helpers
  Future<void> save(String key, dynamic value) async {
    await _prefsBox?.put(key, value);
  }

  T? get<T>(String key) => _prefsBox?.get(key) as T?;

  Future<void> delete(String key) async {
    await _prefsBox?.delete(key);
  }

  Future<void> clearAll() async {
    await _prefsBox?.clear();
    for (final table in [
      'cached_profiles',
      'cached_vehicles',
      'cached_policies',
      'cached_exchange_rates',
      'pending_sync_queue',
    ]) {
      await _db?.delete(table);
    }
  }

  Future<void> dispose() async {
    await _db?.close();
    await _prefsBox?.close();
  }
}
