import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const _dbName = 'hadith.db';
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path   = join(dbPath, _dbName);

    // Check if the database exists
    final exists = await databaseExists(path);

    if (!exists) {
      // Should happen only the first time you launch your application
      print('Creating new copy from asset');

      // Make sure the parent directory exists
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}
      
      // Copy from asset
      ByteData data = await rootBundle.load('assets/db/$_dbName');
      List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      
      // Write and flush the bytes written
      await File(path).writeAsBytes(bytes, flush: true);
    } else {
      print('Opening existing database');
    }

    // Open the database
    return await openDatabase(path, readOnly: true);
  }
}
