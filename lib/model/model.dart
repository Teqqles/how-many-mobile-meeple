import 'package:flutter/cupertino.dart';
import 'package:how_many_mobile_meeple/platform/web/url_fragment_extractor.dart';
import 'package:how_many_mobile_meeple/storage/storage_factory.dart';
import 'package:how_many_mobile_meeple/storage/stored_preferences.dart';
import 'package:provider/provider.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';

import 'package:how_many_mobile_meeple/model/bgg_cache.dart';
import 'package:how_many_mobile_meeple/model/item.dart';

import '../api/prefetch_service.dart';
import '../app_common.dart';
import 'game.dart';
import 'games.dart';
import 'items.dart';

class AppModel extends ChangeNotifier {
  static AppModel of(BuildContext context, {bool listen = true}) =>
      Provider.of<AppModel>(context, listen: listen);

  static int _defaultCacheDurationInMinutes = 30;
  static int _unsetCacheDurationInMinutes = -1;

  bool hasLoadedPersistedData = false;
  bool pageRefreshed = false;

  String? title;

  Items _items = Items([]);
  BggCache _bggCache = BggCache(Games(), _unsetCacheDurationInMinutes);

  late Settings _settings;
  Orientation? screenOrientation;

  Items get items => _items;

  BggCache get bggCache => _bggCache;

  Settings get settings => _settings;

  SortOrder sortDirection = SortOrder.Desc;

  SortableGameField sortGameField = SortableGameField.rating;

  UrlFragmentExtractor _extractor = UrlFragmentExtractor(Uri.base);

  AppModel() {
    _settings = Settings.defaultSettings();
  }

  Future<void> refreshFromUrl() async {
    if (_extractor.containsModel()) {
      await replaceItems(_extractor.extractItems());
      var extractedSettings = _extractor.extractSettings();
      extractedSettings = _rebuildUrlMechanics(extractedSettings);
      if (_settings != extractedSettings) {
        _settings.updateAllSettings(extractedSettings);
        invalidateCache();
      }
    }
  }

  Settings _rebuildUrlMechanics(Settings extractedSettings) {
    final mechanicsSetting =
        extractedSettings.setting(Settings.filterMechanics.name);
    mechanicsSetting.value = mechanicsSetting.getList();
    return extractedSettings;
  }

  void toggleSortDirection() {
    sortDirection =
        sortDirection == SortOrder.Asc ? SortOrder.Desc : SortOrder.Asc;
  }

  Future<void> addItem(Item item) async {
    _items.itemList.add(item);
    invalidateCache();
    await updateStore();
  }

  Future<void> replaceItems(Items items) async {
    if (items == _items) {
      return;
    }
    _items = items;
    invalidateCache();
    await updateStore();
  }

  Future<void> replaceSettings(Settings settings) async {
    var newSettings = Settings.defaultSettings();
    for (var setting in settings.allSettings.values) {
      newSettings.updateSetting(setting);
    }
    _settings = newSettings;
    invalidateCache();
    await updateStore();
  }

  void invalidateCache() {
    _bggCache.makeStale();
  }

  void replaceCache(Games games) {
    if (games == _bggCache.games) {
      _bggCache.refreshCacheTimestamp();
    } else {
      _bggCache = BggCache(games, _defaultCacheDurationInMinutes);
    }
  }

  Future<void> deleteItem(Item item) async {
    _items.itemList.remove(item);
    await _storeItems(_items);
    invalidateCache();
    notifyListeners();
  }

  Future<void> updateStore() async {
    await Future.wait([
      _storeSettings(settings),
      _storeItems(_items),
    ]);
    notifyListeners();
  }

  void refreshState() => notifyListeners();

  Future<void> loadStoredData() async {
    if (_extractor.containsModel()) {
      return;
    }
    StoredPreferences store = await StorageFactory.getStoredPreferences();
    await store.clearIfVersionChanged();
    _items = await store.loadItems(AppCommon.maxItemsFromBgg);
    replaceSettings(await store.loadSettings(settings));
    hasLoadedPersistedData = true;
    notifyListeners();
    for (final item in _items.itemList) {
      PrefetchService.warmCache(item);
    }
  }

  Future<void> _storeSettings(Settings settings) async {
    StoredPreferences store = await StorageFactory.getStoredPreferences();
    await store.saveSettings(settings);
  }

  Future<void> _storeItems(Items items) async {
    StoredPreferences store = await StorageFactory.getStoredPreferences();
    await store.saveItems(items, AppCommon.maxItemsFromBgg);
  }
}
