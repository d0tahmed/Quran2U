import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const _dbName   = 'hadith_v2.db';
  static const _assetGz  = 'assets/db/hadith_v2.db.gz';
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final dbDir  = await getDatabasesPath();
    final path   = join(dbDir, _dbName);

    // Try to open an existing DB first.
    if (await databaseExists(path)) {
      try {
        final db = await openDatabase(path, readOnly: true);
        debugPrint('DatabaseHelper: opened existing database');
        return db;
      } catch (e) {
        // File exists but is corrupt (e.g. interrupted write on a previous run).
        debugPrint('DatabaseHelper: corrupt database detected – rebuilding ($e)');
        await File(path).delete();
      }
    }

    // ── First-run (or rebuild after corruption): decompress asset ──────────
    debugPrint('DatabaseHelper: decompressing asset → $path');

    try {
      await Directory(dirname(path)).create(recursive: true);
    } catch (_) {}

    // Load the compressed asset bytes on the main isolate
    // (rootBundle requires the main isolate).
    final ByteData data = await rootBundle.load(_assetGz);
    final List<int> gzBytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );

    // Decompress in a background isolate so the UI never jank.
    final List<int> rawBytes = await Isolate.run(
      () => GZipCodec().decode(gzBytes),
    );

    // Write to a temp file first, then rename atomically.
    // This ensures we never leave a partial/corrupt file if the app is killed.
    final tmpPath = '$path.tmp';
    await File(tmpPath).writeAsBytes(rawBytes, flush: true);
    await File(tmpPath).rename(path);          // atomic on same filesystem

    debugPrint(
      'DatabaseHelper: ready — ${(rawBytes.length / 1024 / 1024).toStringAsFixed(1)} MB',
    );

    return await openDatabase(path, readOnly: true);
  }

  /// Wipe the cached database so it is re-extracted on next access.
  /// Use this when shipping a new DB version.
  static Future<void> resetDatabase() async {
    _db = null;
    final dbDir = await getDatabasesPath();
    for (final name in [_dbName, '$_dbName.tmp']) {
      final f = File(join(dbDir, name));
      if (await f.exists()) await f.delete();
    }
    debugPrint('DatabaseHelper: cache cleared');
  }
}
