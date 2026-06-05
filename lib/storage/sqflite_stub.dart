/// Stub for sqflite on web platform
class Database {
  Future<int> rawInsert(String sql, [List<Object?>? arguments]) async {
    throw UnsupportedError('sqflite is not supported on web');
  }

  Future<List<Map<String, Object?>>> rawQuery(String sql,
      [List<Object?>? arguments]) async {
    throw UnsupportedError('sqflite is not supported on web');
  }

  Future<int> rawDelete(String sql, [List<Object?>? arguments]) async {
    throw UnsupportedError('sqflite is not supported on web');
  }

  Future<void> execute(String sql, [List<Object?>? arguments]) async {
    throw UnsupportedError('sqflite is not supported on web');
  }
}

Future<Database> openDatabase(
  String path, {
  int? version,
  Function? onCreate,
  Function? onUpgrade,
}) async {
  throw UnsupportedError('sqflite is not supported on web');
}

Future<String> getDatabasesPath() async {
  throw UnsupportedError('sqflite is not supported on web');
}
