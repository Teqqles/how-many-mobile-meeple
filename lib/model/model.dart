import 'package:flutter/cupertino.dart';
import 'package:how_many_mobile_meeple/storage/stored_preferences.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:how_many_mobile_meeple/model/bgg_cache.dart';
import 'package:how_many_mobile_meeple/model/item.dart';

import 'dart:convert';

import '../game_config.dart';
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
  }

  void deleteItem(Item item) {
    var itemIndex = _items.indexOf(item);
    _items.remove(item);
    _removeItemFromStore(itemIndex);
    this.invalidateCache();
  }

  void _removeItemFromStore(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove("$_itemStoreNamePrefix$index");
  }

  void updateStore() {
    _storeSettings(settings);
    _storeItems(items);
    notifyListeners();
  }

  void loadStoredData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    StoredPreferences store = StoredPreferences(prefs);
    _items = _loadItems(prefs);
    _settings = await store.loadSettings(settings);
    this.hasLoadedPersistedData = true;
    this.notifyListeners();
  }

  List<Item> _loadItems(SharedPreferences prefs) {
    List<Item> savedItems = List<Item>();
    for (var i = 0; i < GameConfig.maxItemsFromBgg; i++) {
      if (prefs.containsKey("$_itemStoreNamePrefix$i")) {
        var item = prefs.getString("$_itemStoreNamePrefix$i");
        var loadedItem = Item.fromJson(jsonDecode(item));
        savedItems.add(loadedItem);
      }
    }
    return savedItems;
  }

  void _storeSettings(Settings settings) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    StoredPreferences store = StoredPreferences(prefs);
    store.saveSettings(settings);
  }

  void _storeItems(List<Item> items) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    for (var i = 0; i < items.length; i++) {
      await prefs.setString("$_itemStoreNamePrefix$i", json.encode(items[i]));
    }
  }
}
