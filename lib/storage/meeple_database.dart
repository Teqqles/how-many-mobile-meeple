import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:path/path.dart';

import 'package:sqflite/sqflite.dart';
import 'package:synchronized/synchronized.dart';

abstract class MeepleDatabase {
  MeepleDatabase(this.tableName);

  static String databaseName = 'meeple.db';

  final int version = 1;

  final String tableName;

  String createTable(int version);

  _onCreate(Database db, int version) async {
    await db.execute(createTable(version));
  }

  Database _db;
  final _lock = new Lock();

  Future<Database> getDb() async {
    if (_db == null) {
      await _lock.synchronized(() async {
        if (_db == null) {
          try {
            var path = await initDatabasePath();
            _db =
                await openDatabase(path, version: version, onCreate: _onCreate);
          } catch (e) {
            debugPrint(e.toString());
          }
        }
      });
    }
    return _db;
  }

  Future<String> initDatabasePath() async {
    final String databasePath = await getDatabasesPath();
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
