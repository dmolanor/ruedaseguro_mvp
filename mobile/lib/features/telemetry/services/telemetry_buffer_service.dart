// RS-071 — 15-minute sliding-window telemetry buffer using SQLite.
//
// Sensor reading pipeline (Phase 1.5):
//   sensors_plus → TelemetryBufferService.insertSample()
//                → auto-prune entries older than MAX_WINDOW
//                → on impact: getWindow() → upload to Supabase telemetry_events
//
// This service is ready for sensor activation in Phase 1.5.
// It does NOT activate sensors itself — sensors_plus is commented out
// in pubspec.yaml until Alex confirms the telemetry spec.

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class TelemetrySample {
  final int id;
  final DateTime recordedAt;
  final double? gForce;
  final double? latitude;
  final double? longitude;
  final double? altitudeM;
  final double? speedKmh;

  const TelemetrySample({
    required this.id,
    required this.recordedAt,
    this.gForce,
    this.latitude,
    this.longitude,
    this.altitudeM,
    this.speedKmh,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'recorded_at': recordedAt.millisecondsSinceEpoch,
        'g_force': gForce,
        'latitude': latitude,
        'longitude': longitude,
        'altitude_m': altitudeM,
        'speed_kmh': speedKmh,
      };

  factory TelemetrySample.fromMap(Map<String, dynamic> m) => TelemetrySample(
        id: m['id'] as int,
        recordedAt: DateTime.fromMillisecondsSinceEpoch(m['recorded_at'] as int),
        gForce: (m['g_force'] as num?)?.toDouble(),
        latitude: (m['latitude'] as num?)?.toDouble(),
        longitude: (m['longitude'] as num?)?.toDouble(),
        altitudeM: (m['altitude_m'] as num?)?.toDouble(),
        speedKmh: (m['speed_kmh'] as num?)?.toDouble(),
      );
}

class TelemetryBufferService {
  TelemetryBufferService._();
  static final instance = TelemetryBufferService._();

  static const _dbName = 'rs_telemetry.db';
  static const _tableName = 'anomaly_queue';

  /// Circular buffer: keep 15 minutes of data.
  static const _maxWindow = Duration(minutes: 15);

  /// Auto-prune after every N inserts to avoid unbounded growth.
  static const _pruneEveryN = 50;
  int _insertCount = 0;

  Database? _db;

  /// Call once at app startup (or lazily on first use).
  Future<void> init() async {
    if (_db != null) return;
    final dbPath = join(await getDatabasesPath(), _dbName);
    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, _) => db.execute('''
        CREATE TABLE IF NOT EXISTS $_tableName (
          id          INTEGER PRIMARY KEY AUTOINCREMENT,
          recorded_at INTEGER NOT NULL,
          g_force     REAL,
          latitude    REAL,
          longitude   REAL,
          altitude_m  REAL,
          speed_kmh   REAL
        )
      '''),
    );
  }

  /// Insert a single sensor sample into the circular buffer.
  Future<void> insertSample({
    double? gForce,
    double? latitude,
    double? longitude,
    double? altitudeM,
    double? speedKmh,
  }) async {
    await _ensureInit();
    await _db!.insert(_tableName, {
      'recorded_at': DateTime.now().millisecondsSinceEpoch,
      'g_force': gForce,
      'latitude': latitude,
      'longitude': longitude,
      'altitude_m': altitudeM,
      'speed_kmh': speedKmh,
    });

    _insertCount++;
    if (_insertCount % _pruneEveryN == 0) {
      await pruneOlderThan(_maxWindow);
    }
  }

  /// Returns all samples within [window] of the current time, newest last.
  Future<List<TelemetrySample>> getWindow([Duration? window]) async {
    await _ensureInit();
    final cutoff = DateTime.now()
        .subtract(window ?? _maxWindow)
        .millisecondsSinceEpoch;

    final rows = await _db!.query(
      _tableName,
      where: 'recorded_at >= ?',
      whereArgs: [cutoff],
      orderBy: 'recorded_at ASC',
    );
    return rows.map(TelemetrySample.fromMap).toList();
  }

  /// Deletes all samples older than [maxAge] from the current time.
  Future<void> pruneOlderThan(Duration maxAge) async {
    await _ensureInit();
    final cutoff =
        DateTime.now().subtract(maxAge).millisecondsSinceEpoch;
    await _db!.delete(
      _tableName,
      where: 'recorded_at < ?',
      whereArgs: [cutoff],
    );
  }

  /// Clears the entire buffer (call after a successful upload to Supabase).
  Future<void> clear() async {
    await _ensureInit();
    await _db!.delete(_tableName);
  }

  /// Returns the number of samples currently in the buffer.
  Future<int> get sampleCount async {
    await _ensureInit();
    final result =
        await _db!.rawQuery('SELECT COUNT(*) as cnt FROM $_tableName');
    return (result.first['cnt'] as int?) ?? 0;
  }

  /// Returns the most recent G-force reading, or null if buffer is empty.
  Future<double?> get peakGForce async {
    await _ensureInit();
    final result = await _db!.rawQuery(
        'SELECT MAX(g_force) as peak FROM $_tableName WHERE g_force IS NOT NULL');
    return (result.first['peak'] as num?)?.toDouble();
  }

  Future<void> _ensureInit() async {
    if (_db == null) await init();
  }
}
