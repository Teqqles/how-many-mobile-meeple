import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:how_many_mobile_meeple/storage/stored_preferences.dart';
import 'package:how_many_mobile_meeple/storage/preferences_history_interface.dart';
import 'package:how_many_mobile_meeple/storage/preferences_history_web.dart';
import 'package:how_many_mobile_meeple/storage/preferences_history.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class StorageFactory {
  static Future<StoredPreferences> getStoredPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return StoredPreferences(prefs);
  }

  static PreferencesHistoryInterface getPreferencesHistory() {
    if (kIsWeb) {
      return PreferencesHistoryWeb();
    } else {
      return PreferencesHistoryDb();
    }
  }
}
