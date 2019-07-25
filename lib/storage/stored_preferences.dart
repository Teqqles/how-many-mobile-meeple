import 'dart:convert';

import 'package:how_many_mobile_meeple/model/setting.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';
import 'package:how_many_mobile_meeple/model/items.dart';
import 'package:how_many_mobile_meeple/model/item.dart';
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
    for (Setting setting in settings.allSettings.values) {
      await _prefs.setString(setting.name, json.encode(setting));
    }
    return true;
  }

  Future<Settings> loadSettings(Settings settingsToRetrieve) async {
    Settings settings = settingsToRetrieve.clone();
    for (String settingName in settingsToRetrieve.allSettings.keys) {
      if (_prefs.containsKey(settingName)) {
        Setting loadedSetting =
            Setting.fromJson(jsonDecode(_prefs.getString(settingName)));
        settings.updateSetting(loadedSetting);
      }
    }
    return settings;
  }

  Future<bool> saveItems(Items items, int maxItemsToLoadFromStore) async {
    for (var i = 0; i < maxItemsToLoadFromStore; i++) {
      await _prefs.remove("${Items.itemStoreNamePrefix}$i");
    }
    for (var i = 0; i < items.items.length; i++) {
      var item = items.items[i];
      await _prefs.setString(
          "${Items.itemStoreNamePrefix}$i", json.encode(item));
    }
    return true;
  }

  Future<Items> loadItems(int maxItemsToLoadFromStore) async {
    List<Item> savedItems = List<Item>();
    for (int i = 0; i < maxItemsToLoadFromStore; i++) {
      String itemId = "${Items.itemStoreNamePrefix}$i";
      if (_prefs.containsKey(itemId)) {
        String item = _prefs.getString(itemId);
        var loadedItem = Item.fromJson(jsonDecode(item));
        savedItems.add(loadedItem);
      }
    }
    return Items(savedItems);
  }
}
