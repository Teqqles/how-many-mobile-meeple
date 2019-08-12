import 'dart:convert';

import 'package:how_many_mobile_meeple/model/app_preferences.dart';

import 'meeple_database.dart';

class PreferencesHistory extends MeepleDatabase {
  static final String table = 'preference_history';

  PreferencesHistory() : super(table);

  @override
  String createTable(int version) {
    String tableStatement =
        "CREATE TABLE $tableName (id TEXT PRIMARY KEY, title TEXT, timestamp INTEGER, items TEXT, settings TEXT)";
    return tableStatement;
  }

  void storePreference(AppPreferences preferences) async {
    String insertStatement =
        "INSERT INTO $tableName (id, title, timestamp, items, settings) VALUES (?, ?, ?, ?, ?)"; // todo upsert

    var db = await getDb(); // todo move this to database abstract class
    await db.rawInsert(insertStatement, [
      preferences.id,
      getSecondsTimestamp(),
      json.encode(preferences.items),
      json.encode(preferences.settings)
    ]);
  }

  List<AppPreferences> _tableDataToPreferences(List<Map> records) {
    return records.map((json) => AppPreferences.fromJson(json));
  }

  Future<AppPreferences> loadPreference(int preferenceId) async {
    String selectPreferenceStatement =
        'SELECT title, items, settings FROM $tableName WHERE id = ?';
    var db = await getDb();
    List<Map> list =
        await db.rawQuery(selectPreferenceStatement, [preferenceId]);
    return _tableDataToPreferences(list).first;
  }

  Future<bool> deletePreference(int preferenceId) async {
    String selectPreferenceStatement = 'DELETE FROM $tableName WHERE id = ?';
    var db = await getDb();
    int deletions =
        await db.rawDelete(selectPreferenceStatement, [preferenceId]);
    return deletions > 0;
  }

  Future<List<AppPreferences>> loadAllPreferences() async {
    String selectPreferenceStatement =
        'SELECT id, title, items, settings FROM $tableName ORDER BY timestamp DESC LIMIT 5';
    var db = await getDb();
    List<Map> list = await db.rawQuery(selectPreferenceStatement);
    return _tableDataToPreferences(list);
  }
}
