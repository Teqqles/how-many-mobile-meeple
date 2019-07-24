import 'package:flutter/cupertino.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:how_many_mobile_meeple/model/bgg_cache.dart';
import 'package:how_many_mobile_meeple/model/item.dart';

import 'dart:convert';

import 'games.dart';

class AppModel extends Model {
  static AppModel of(BuildContext context) => ScopedModel.of<AppModel>(context);

  static int _defaultCacheDurationInMinutes = 30;
  static int _unsetCacheDurationInMinutes = -1;

  bool hasLoadedPersistedData = false;

  List<Item> _items = [];
  BggCache _bggCache = BggCache(Games(), _unsetCacheDurationInMinutes);
  Settings _settings = Settings({
    Settings.fieldsToReturnFromApi.name: Settings.fieldsToReturnFromApi,
    Settings.filterMinimumTimeToPlay.name: Settings.filterMinimumTimeToPlay,
    Settings.filterMaximumTimeToPlay.name: Settings.filterMaximumTimeToPlay,
    Settings.filterNumberOfPlayers.name: Settings.filterNumberOfPlayers
  });
  Orientation screenOrientation;

  List<Item> get items => _items;

  BggCache get bggCache => _bggCache;

  Settings get settings => _settings;

  void addItem(Item item) {
    _items.add(item);
    this.invalidateCache();
    this.updateStore();
  }

  void invalidateCache() {
    _bggCache.makeStale();
  }

  void replaceCache(Games games) {
    _bggCache = BggCache(games, _defaultCacheDurationInMinutes);
    this.updateStore();
  }

  void deleteItem(Item item) {
    _items.remove(item);
    this.invalidateCache();
    this.updateStore();
  }

  void updateStore() {
    _storeSettings(settings);
    notifyListeners();
  }

  void loadStoredData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    for (var setting in settings.allSettings.values) {
      var loadedSetting =
          Setting.fromJson(jsonDecode(prefs.getString(setting.name)));
      this.settings.updateSetting(loadedSetting);
    }
    this.hasLoadedPersistedData = true;
    this.notifyListeners();
  }

  void _storeSettings(Settings settings) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    for (var setting in settings.allSettings.values) {
      await prefs.setString(setting.name, json.encode(setting));
    }
  }
}
