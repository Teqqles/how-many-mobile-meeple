import 'dart:convert';

import 'package:how_many_mobile_meeple/model/setting.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StoredPreferences {
  static Future<SharedPreferences> getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  SharedPreferences _prefs;

  StoredPreferences(SharedPreferences sharedPreferences) {
    _prefs = sharedPreferences;
  }

  Future<bool> saveSettings(Settings settings) async {
    for (var setting in settings.allSettings.values) {
      await _prefs.setString(setting.name, json.encode(setting));
    }
    return true;
  }

  Future<Settings> loadSettings(Settings settingsToRetrieve) async {
    Settings settings = Settings({});
    for (var settingName in settingsToRetrieve.allSettings.keys) {
      if (_prefs.containsKey(settingName)) {
        var loadedSetting =
            Setting.fromJson(jsonDecode(_prefs.getString(settingName)));
        settings.updateSetting(loadedSetting);
      }
    }
    return settings;
  }
}
