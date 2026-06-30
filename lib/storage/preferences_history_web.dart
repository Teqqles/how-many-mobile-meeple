// coverage:ignore-file
import 'dart:convert';
import 'package:how_many_mobile_meeple/model/app_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'preferences_history_interface.dart';

/// Web implementation of preferences history using SharedPreferences
class PreferencesHistoryWeb implements PreferencesHistoryInterface {
  static const String _keyPrefix = 'pref_history_';
  static const String _indexKey = 'pref_history_index';
  static const int _maxHistoryItems = 5;

  @override
  Future<void> storePreference(AppPreferences preferences) async {
    final prefs = await SharedPreferences.getInstance();

    // Get current index list
    final indexJson = prefs.getString(_indexKey);
    List<String> index =
        indexJson != null ? List<String>.from(jsonDecode(indexJson)) : [];

    // Add new preference ID to index
    final id =
        preferences.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    if (!index.contains(id)) {
      index.insert(0, id);
    }

    // Keep only last N items
    if (index.length > _maxHistoryItems) {
      final removedIds = index.sublist(_maxHistoryItems);
      for (var removeId in removedIds) {
        await prefs.remove('$_keyPrefix$removeId');
      }
      index = index.sublist(0, _maxHistoryItems);
    }

    // Save preference
    await prefs.setString('$_keyPrefix$id', jsonEncode(preferences.toJson()));

    // Save updated index
    await prefs.setString(_indexKey, jsonEncode(index));
  }

  @override
  Future<AppPreferences> loadPreference(int preferenceId) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('$_keyPrefix$preferenceId');
    if (json == null) {
      throw Exception('Preference not found: $preferenceId');
    }
    return AppPreferences.fromJson(jsonDecode(json));
  }

  @override
  Future<bool> deletePreference(String preferenceId) async {
    final prefs = await SharedPreferences.getInstance();

    // Remove from index
    final indexJson = prefs.getString(_indexKey);
    if (indexJson != null) {
      List<String> index = List<String>.from(jsonDecode(indexJson));
      index.remove(preferenceId);
      await prefs.setString(_indexKey, jsonEncode(index));
    }

    // Remove preference data
    return await prefs.remove('$_keyPrefix$preferenceId');
  }

  @override
  Future<List<AppPreferences>> loadAllPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // Get index
    final indexJson = prefs.getString(_indexKey);
    if (indexJson == null) {
      return [];
    }

    List<String> index = List<String>.from(jsonDecode(indexJson));
    List<AppPreferences> result = [];

    // Load each preference
    for (var id in index) {
      final json = prefs.getString('$_keyPrefix$id');
      if (json != null) {
        try {
          result.add(AppPreferences.fromJson(jsonDecode(json)));
        } catch (e) {
          // Skip invalid entries
          continue;
        }
      }
    }

    return result;
  }
}
