import 'package:flutter/cupertino.dart';
import 'package:how_many_mobile_meeple/platform/web/url_fragment_extractor.dart';
import 'package:how_many_mobile_meeple/storage/storage_factory.dart';
import 'package:how_many_mobile_meeple/storage/stored_preferences.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';

import 'package:how_many_mobile_meeple/model/bgg_cache.dart';
import 'package:how_many_mobile_meeple/model/item.dart';

import '../app_common.dart';
import '../str_cast.dart';
import 'game.dart';
import 'games.dart';
import 'items.dart';

class AppModel extends Model {
  static AppModel of(BuildContext context) => ScopedModel.of<AppModel>(context);

  static int _defaultCacheDurationInMinutes = 30;
  static int _unsetCacheDurationInMinutes = -1;

  bool hasLoadedPersistedData = false;

  String title;

  Items _items = Items([]);
  BggCache _bggCache = BggCache(Games(), _unsetCacheDurationInMinutes);

  Settings _settings;
  Orientation screenOrientation;

  Items get items => _items;

  BggCache get bggCache => _bggCache;

  Settings get settings => _settings;

  SortOrder sortDirection = SortOrder.Desc;

  SortableGameField sortGameField = SortableGameField.rating;

  UrlFragmentExtractor _extractor = UrlFragmentExtractor(Uri.base);

  AppModel() {
    _settings = Settings.defaultSettings();
  }

  void refreshFromUrl() {
    if (_extractor.containsModel()) {
      replaceItems(_extractor.extractItems());
      var extractedSettings = _extractor.extractSettings();
      extractedSettings = _rebuildUrlMechanics(extractedSettings);
      _settings.updateAllSettings(extractedSettings);
    }
  }

  Settings _rebuildUrlMechanics(Settings extractedSettings) {
    extractedSettings.setting(Settings.filterMechanics.name).value =
        StrCast(extractedSettings.setting(Settings.filterMechanics.name).value).castToList();
    return extractedSettings;
  }

  void toggleSortDirection() {
    sortDirection =
        sortDirection == SortOrder.Asc ? SortOrder.Desc : SortOrder.Asc;
  }

  void addItem(Item item) {
    _items.itemList.add(item);
    this.invalidateCache();
    this.updateStore();
  }

  void replaceItems(Items items) {
    _items = items;
    this.invalidateCache();
    this.updateStore();
  }

  void replaceSettings(Settings settings) {
    var newSettings = Settings.defaultSettings();
    for (var setting in settings.allSettings.values) {
      newSettings.updateSetting(setting);
    }
    _settings = newSettings;
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
    _items.itemList.remove(item);
    _storeItems(_items);
    this.invalidateCache();
    notifyListeners();
  }

  void updateStore() {
    _storeSettings(settings);
    _storeItems(_items);
    notifyListeners();
  }

  void refreshState() => this.notifyListeners();

  void loadStoredData() async {
    if (_extractor.containsModel()) {
      return;
    }
    StoredPreferences store = await StorageFactory.getStoredPreferences();
    _items = await store.loadItems(AppCommon.maxItemsFromBgg);
    this.replaceSettings(await store.loadSettings(settings));
    this.hasLoadedPersistedData = true;
    this.notifyListeners();
  }

  void _storeSettings(Settings settings) async {
    StoredPreferences store = await StorageFactory.getStoredPreferences();
    store.saveSettings(settings);
  }

  void _storeItems(Items items) async {
    StoredPreferences store = await StorageFactory.getStoredPreferences();
    store.saveItems(items, AppCommon.maxItemsFromBgg);
  }
}
