// coverage:ignore-file
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:path/path.dart';

// Conditional import for sqflite
import 'sqflite_stub.dart' if (dart.library.io) 'package:sqflite/sqflite.dart';
import 'sqflite_stub.dart' if (dart.library.io) 'package:sqflite/sqflite.dart'
    as sqflite_common;
import 'package:synchronized/synchronized.dart';

abstract class MeepleDatabase {
  MeepleDatabase(this.tableName);

  static String databaseName = 'meeple.db';

  int dbVersion();

  final String tableName;

  void createDatabase(Database db, int version);

  void upgradeDb(Database db, int oldVersion, int newVersion);

  Future<void> _onCreate(Database db, int version) async {
    createDatabase(db, version);
  }

  Future<void> _onUpdate(Database db, int oldVersion, int newVersion) async {
    upgradeDb(db, oldVersion, newVersion);
  }

  Database? _db;
  final _lock = Lock();

  Future<Database> getDb() async {
    if (_db == null) {
      await _lock.synchronized(() async {
        if (_db == null) {
          try {
            var path = await initDatabasePath();
            _db = await openDatabase(path,
                version: dbVersion(),
                onCreate: _onCreate,
                onUpgrade: _onUpdate);
          } catch (e) {
            debugPrint(e.toString());
          }
        }
      });
    }
    return _db!;
  }

  Future<String> initDatabasePath() async {
    final String databasePath = await sqflite_common.getDatabasesPath();
    final String path = join(databasePath, databaseName);

    if (!await Directory(dirname(path)).exists()) {
      await Directory(dirname(path)).create(recursive: true);
    }
    return path;
  }

  int getSecondsTimestamp() {
    double timestampInSeconds = DateTime.now().millisecondsSinceEpoch / 1000;
    return timestampInSeconds.floor();
  }
}
