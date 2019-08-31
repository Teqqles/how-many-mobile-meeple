import 'dart:convert';

import 'package:how_many_mobile_meeple/model/app_preferences.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';

import 'meeple_database.dart';

class PreferencesHistoryDb extends MeepleDatabase {
  static final String table = 'preference_history';

  PreferencesHistoryDb() : super(table);

  @override
  String createTable(int version) {
    String tableStatement = "CREATE TABLE $tableName (id TEXT PRIMARY KEY, "
        "title TEXT, "
        "timestamp INTEGER, "
        "items TEXT, "
        "setting_whitelist TEXT, "
        "setting_num_players TEXT, "
        "setting_min_time TEXT, "
        "setting_max_time TEXT, "
        "setting_complexity TEXT, "
        "setting_user_recommendations TEXT, "
        "setting_mechanic TEXT, "
        "setting_use_all_mechanics TEXT, "
        "setting_include_expansions TEXT)";
    return tableStatement;
  }

  void storePreference(AppPreferences preferences) async {
    String insertStatement = "INSERT OR REPLACE INTO $tableName (id, "
        "title, "
        "timestamp, "
        "items, "
        "setting_whitelist, "
        "setting_num_players, "
        "setting_min_time, "
        "setting_max_time, "
        "setting_complexity, "
        "setting_user_recommendations, "
        "setting_mechanic, "
        "setting_use_all_mechanics, "
        "setting_include_expansions) "
        "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

    var db = await getDb();
    await db.rawInsert(insertStatement, [
      preferences.id,
      preferences.title,
      getSecondsTimestamp(),
      json.encode(preferences.items),
      json.encode(
          preferences.settings.setting(Settings.fieldsToReturnFromApi.name)),
      json.encode(
          preferences.settings.setting(Settings.filterNumberOfPlayers.name)),
      json.encode(
          preferences.settings.setting(Settings.filterMinimumTimeToPlay.name)),
      json.encode(
          preferences.settings.setting(Settings.filterMaximumTimeToPlay.name)),
      json.encode(preferences.settings.setting(Settings.filterComplexity.name)),
      json.encode(preferences.settings
          .setting(Settings.filterUsingUserRecommendations.name)),
      json.encode(preferences.settings.setting(Settings.filterMechanics.name)),
      json.encode(
          preferences.settings.setting(Settings.filterUseAllMechanics.name)),
      json.encode(
          preferences.settings.setting(Settings.filterIncludesExpansions.name)),
    ]);
  }

  List<AppPreferences> _tableDataToPreferences(List<Map> records) {
    Iterable<AppPreferences> prefs =
        records.map((Map json) => AppPreferences.fromDb(json));
    return prefs.toList();
  }

  Future<AppPreferences> loadPreference(int preferenceId) async {
    String selectPreferenceStatement = "SELECT * "
        "FROM $tableName WHERE id = ?";
    var db = await getDb();
    List<Map> list =
        await db.rawQuery(selectPreferenceStatement, [preferenceId]);
    return _tableDataToPreferences(list).first;
  }

  Future<bool> deletePreference(String preferenceId) async {
    String selectPreferenceStatement = 'DELETE FROM $tableName WHERE id = ?';
    var db = await getDb();
    int deletions =
        await db.rawDelete(selectPreferenceStatement, [preferenceId]);
    return deletions > 0;
  }

  Future<List<AppPreferences>> loadAllPreferences() async {
    String selectPreferenceStatement =
        'SELECT * FROM $tableName ORDER BY timestamp DESC LIMIT 5';
    var db = await getDb();
    List<Map> list = await db.rawQuery(selectPreferenceStatement);
    return _tableDataToPreferences(list);
  }
}
