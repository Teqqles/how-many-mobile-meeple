import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:how_many_mobile_meeple/api/http_retry_client.dart';
import 'package:how_many_mobile_meeple/api/plays_service.dart';
import 'package:how_many_mobile_meeple/model/play_data.dart';
import 'package:how_many_mobile_meeple/platform/web/url_fragment_extractor.dart';
import 'package:how_many_mobile_meeple/storage/preferences_history_interface.dart';
import 'package:how_many_mobile_meeple/storage/storage_factory.dart';
import 'package:how_many_mobile_meeple/storage/stored_preferences.dart';
import 'package:provider/provider.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:how_many_mobile_meeple/model/app_preferences.dart';
import 'package:how_many_mobile_meeple/model/bgg_cache.dart';
import 'package:how_many_mobile_meeple/model/game_request.dart';
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
  bool _urlConsumed = false;

  String? title;

  final PreferencesHistoryInterface _preferencesHistory;

  Items _items = Items([]);
  BggCache _bggCache = BggCache(Games(), _unsetCacheDurationInMinutes);
  StoredPreferences? _store;
  List<AppPreferences>? _cachedPreferences;

  String? _primaryPlayer;
  Map<int, PlayData> _playsData = {};
  bool _playsLoaded = false;
  Set<int> _collectionGameIds = {};

  late Settings _settings;
  Orientation? screenOrientation;

  Items get items => _items;

  BggCache get bggCache => _bggCache;

  Settings get settings => _settings;

  String? get primaryPlayer => _primaryPlayer;

  set primaryPlayer(String? value) {
    if (_primaryPlayer == value) return;
    _playsRetryTimer?.cancel();
    _primaryPlayer = value;
    _playsLoaded = false;
    _playsData = {};
    _collectionGameIds = {};
    _persistPrimaryPlayer();
    notifyListeners();
    if (value != null) {
      loadPlays();
    }
  }

  Map<int, PlayData> get playsData => _playsData;

  bool get playsLoaded => _playsLoaded;

  int getPlayCount(int gameId) => _playsData[gameId]?.totalPlays ?? 0;

  bool isUnplayed(int gameId) => getPlayCount(gameId) == 0;

  bool isInCollection(int gameId) => _collectionGameIds.contains(gameId);

  Future<void>? _loadPlaysInFlight;
  Timer? _playsRetryTimer;

  Future<void> loadPlays() {
    if (_primaryPlayer == null) return Future.value();
    return _loadPlaysInFlight ??= _doLoadPlays();
  }

  Future<void> _doLoadPlays() async {
    try {
      final results = await Future.wait([
        PlaysService.fetchPlays(_primaryPlayer!),
        _fetchCollectionIds(_primaryPlayer!),
      ]);
      final playsResult = results[0] as PlaysResult;
      _playsData = playsResult.plays;
      _collectionGameIds = results[1] as Set<int>;
      _playsLoaded = true;
      notifyListeners();

      if (!playsResult.complete) {
        _schedulePlaysRetry(playsResult.retryAfterSeconds);
      }
    } finally {
      _loadPlaysInFlight = null;
    }
  }

  void _schedulePlaysRetry(int delaySeconds) {
    _playsRetryTimer?.cancel();
    final seconds = delaySeconds > 0 ? delaySeconds : 30;
    _playsRetryTimer = Timer(Duration(seconds: seconds), () {
      PlaysService.clearCache();
      loadPlays();
    });
  }

  Future<Set<int>> _fetchCollectionIds(String username) async {
    final url = Uri.parse(
        '${AppCommon.boardGameGeekProxyUrl}/collection/${Uri.encodeComponent(username)}');
    final headers = {
      Settings.fieldsToReturnFromApi.header!:
          Settings.fieldsToReturnFromApi.value.toString(),
    };
    final response = await HttpRetryClient.getWithRetry(url, headers: headers);
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map<int>((g) => g['id'] as int).toSet();
    }
    return {};
  }

  Future<void> _persistPrimaryPlayer() async {
    final prefs = await SharedPreferences.getInstance();
    if (_primaryPlayer != null) {
      await prefs.setString('primary_player', _primaryPlayer!);
    } else {
      await prefs.remove('primary_player');
    }
  }

  SortOrder sortDirection = SortOrder.Desc;

  SortableGameField sortGameField = SortableGameField.rating;

  UrlFragmentExtractor _extractor = UrlFragmentExtractor(Uri.base);

  AppModel({PreferencesHistoryInterface? preferencesHistory})
      : _preferencesHistory =
            preferencesHistory ?? StorageFactory.getPreferencesHistory() {
    _settings = Settings.defaultSettings();
  }

  Future<void> refreshFromUrl() async {
    if (_urlConsumed) return;
    if (_extractor.containsModel()) {
      _urlConsumed = true;
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
    if (item.itemType == ItemType.collection && _primaryPlayer == null) {
      _primaryPlayer = item.name;
      _persistPrimaryPlayer();
    }
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

  GameRequest buildRequest() => GameRequest.from(_settings, _items);

  void invalidateCache() {
    _bggCache.makeStale();
    notifyListeners();
  }

  void replaceCache(Games games, GameRequest request) {
    if (request != buildRequest()) {
      return;
    }
    if (games == _bggCache.games) {
      _bggCache.refreshCacheTimestamp();
    } else {
      _bggCache = BggCache(games, _defaultCacheDurationInMinutes);
    }
  }

  Future<void> deleteItem(Item item) async {
    _items.itemList.remove(item);
    if (item.itemType == ItemType.collection && _primaryPlayer == item.name) {
      final nextCollection = _items.itemList
          .where((i) => i.itemType == ItemType.collection)
          .toList();
      _primaryPlayer =
          nextCollection.isNotEmpty ? nextCollection.first.name : null;
      _persistPrimaryPlayer();
    }
    invalidateCache();
    await _storeItems(_items);
  }

  Future<void> updateStore() async {
    await Future.wait([
      _storeSettings(settings),
      _storeItems(_items),
    ]);
    notifyListeners();
  }

  Future<List<AppPreferences>> getSavedPreferences() async {
    _cachedPreferences ??= await _preferencesHistory.loadAllPreferences();
    return _cachedPreferences!;
  }

  void invalidatePreferencesCache() {
    _cachedPreferences = null;
    notifyListeners();
  }

  void refreshState() => notifyListeners();

  Future<StoredPreferences> _getStore() async {
    _store ??= await StorageFactory.getStoredPreferences();
    return _store!;
  }

  Future<void> loadStoredData() async {
    if (_extractor.containsModel()) {
      hasLoadedPersistedData = true;
      _urlConsumed = true;
    } else {
      final store = await _getStore();
      _items = await store.loadItems(AppCommon.maxItemsFromBgg);
      replaceSettings(await store.loadSettings(settings));
      hasLoadedPersistedData = true;
    }

    final prefs = await SharedPreferences.getInstance();
    _primaryPlayer = prefs.getString('primary_player');
    notifyListeners();

    if (_primaryPlayer != null) {
      loadPlays();
    }
    for (final item in _items.itemList) {
      if (item.itemType == ItemType.hotList) continue;
      PrefetchService.warmCache(item);
    }
  }

  Future<void> _storeSettings(Settings settings) async {
    final store = await _getStore();
    await store.saveSettings(settings);
  }

  Future<void> _storeItems(Items items) async {
    final store = await _getStore();
    await store.saveItems(items, AppCommon.maxItemsFromBgg);
  }
}
