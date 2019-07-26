import 'package:flutter/cupertino.dart';
import 'package:how_many_mobile_meeple/storage/storage_factory.dart';
import 'package:how_many_mobile_meeple/storage/stored_preferences.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';

import 'package:how_many_mobile_meeple/model/bgg_cache.dart';
import 'package:how_many_mobile_meeple/model/item.dart';

import '../game_config.dart';
import 'games.dart';
import 'items.dart';

class AppModel extends Model {
  static AppModel of(BuildContext context) => ScopedModel.of<AppModel>(context);

  static int _defaultCacheDurationInMinutes = 30;
  static int _unsetCacheDurationInMinutes = -1;

  bool hasLoadedPersistedData = false;

  Items _items = Items([]);
  BggCache _bggCache = BggCache(Games(), _unsetCacheDurationInMinutes);
  Settings _settings = Settings({
    Settings.fieldsToReturnFromApi.name: Settings.fieldsToReturnFromApi,
    Settings.filterMinimumTimeToPlay.name: Settings.filterMinimumTimeToPlay,
    Settings.filterMaximumTimeToPlay.name: Settings.filterMaximumTimeToPlay,
    Settings.filterNumberOfPlayers.name: Settings.filterNumberOfPlayers,
    Settings.filterUsingUserRecommendations.name:
        Settings.filterUsingUserRecommendations,
    Settings.filterIncludesExpansions.name: Settings.filterIncludesExpansions
  });
  Orientation screenOrientation;

  List<Item> get items => _items.items;

  BggCache get bggCache => _bggCache;

  Settings get settings => _settings;

  void addItem(Item item) {
    _items.items.add(item);
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
    _items.items.remove(item);
    _storeItems(_items);
    this.invalidateCache();
  }

  void updateStore() {
    _storeSettings(settings);
    _storeItems(_items);
    notifyListeners();
  }

  void loadStoredData() async {
    StoredPreferences store = await StorageFactory.getStoredPreferences();
    _items = await store.loadItems(GameConfig.maxItemsFromBgg);
    _settings = await store.loadSettings(settings);
    this.hasLoadedPersistedData = true;
    this.notifyListeners();
  }

  void _storeSettings(Settings settings) async {
    StoredPreferences store = await StorageFactory.getStoredPreferences();
    store.saveSettings(settings);
  }

  void _storeItems(Items items) async {
    StoredPreferences store = await StorageFactory.getStoredPreferences();
    store.saveItems(items, GameConfig.maxItemsFromBgg);
  }
}
