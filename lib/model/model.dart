import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:how_many_mobile_meeple/api/collection_analytics_service.dart';
import 'package:how_many_mobile_meeple/model/collection_analytics.dart';
import 'package:how_many_mobile_meeple/api/http_retry_client.dart';
import 'package:how_many_mobile_meeple/api/plays_service.dart';
import 'package:how_many_mobile_meeple/model/filter_seeder.dart';
import 'package:how_many_mobile_meeple/model/game_night.dart';
import 'package:how_many_mobile_meeple/model/play_data.dart';
import 'package:how_many_mobile_meeple/play_log/play_log_service.dart';
import 'package:how_many_mobile_meeple/platform/web/url_fragment_extractor.dart';
import 'package:how_many_mobile_meeple/storage/preferences_history_interface.dart';
import 'package:how_many_mobile_meeple/storage/storage_factory.dart';
import 'package:how_many_mobile_meeple/storage/stored_preferences.dart';
import 'package:how_many_mobile_meeple/util/retry_scheduler.dart';
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
  Map<int, String> _collectionThumbnails = {};
  PlayLogService? _playLog;
  bool _disposed = false;

  late Settings _settings;
  Orientation? screenOrientation;

  Items get items => _items;

  BggCache get bggCache => _bggCache;

  Settings get settings => _settings;

  String? get primaryPlayer => _primaryPlayer;

  set primaryPlayer(String? value) {
    if (_primaryPlayer == value) return;
    _playsRetry.cancel();
    _primaryPlayer = value;
    _playsLoaded = false;
    _playsData = {};
    _collectionGameIds = {};
    _collectionThumbnails = {};
    _persistPrimaryPlayer();
    notifyListeners();
    if (value != null) {
      loadPlays();
    }
  }

  Map<int, PlayData> get playsData => _playsData;

  bool get playsLoaded => _playsLoaded;

  /// The set of game ids in the primary player's collection, as loaded
  /// alongside their plays. Empty until [loadPlays] has run.
  Set<int> get collectionGameIds => _collectionGameIds;

  @visibleForTesting
  void setPlaysForTest({
    required Map<int, PlayData> playsData,
    required Set<int> collectionGameIds,
    bool loaded = true,
  }) {
    _playsData = playsData;
    _collectionGameIds = collectionGameIds;
    _playsLoaded = loaded;
    notifyListeners();
  }

  /// The primary player's real name as recorded on their BGG plays, if any
  /// play lists them by [_primaryPlayer] as its username. Falls back to the
  /// username so callers always have something to show.
  String? get primaryPlayerName {
    final username = _primaryPlayer;
    if (username == null) return null;
    final lower = username.toLowerCase();
    for (final data in _playsData.values) {
      for (final play in data.plays) {
        for (final player in play.players) {
          if (player.username.toLowerCase() == lower &&
              player.name.isNotEmpty) {
            return player.name;
          }
        }
      }
    }
    return username;
  }

  /// Thumbnail URL for a game if we have it (from the collection), else null.
  String? thumbnailFor(int gameId) => _collectionThumbnails[gameId];

  /// Every individual play loaded from BGG, flattened across games and paired
  /// with the game it belongs to. Aggregated-only games contribute nothing.
  List<BggPlayRecord> get bggPlays => [
    for (final data in _playsData.values)
      for (final play in data.plays)
        BggPlayRecord(
          gameId: data.gameId,
          gameName: data.gameName,
          thumbnail: _collectionThumbnails[data.gameId],
          play: play,
        ),
  ];

  /// Attaches the local play log so locally logged plays are counted alongside
  /// the plays fetched from BGG. Listens for changes so counts update live.
  ///
  /// Safe to call after disposal: the play log loads asynchronously, so the
  /// model may already be torn down (hot restart, fast rebuild) when it lands.
  void attachPlayLog(PlayLogService playLog) {
    if (_disposed || identical(_playLog, playLog)) return;
    _playLog?.removeListener(_onPlayLogChanged);
    _playLog = playLog;
    _playLog!.addListener(_onPlayLogChanged);
    notifyListeners();
  }

  void _onPlayLogChanged() {
    if (_disposed) return;
    notifyListeners();
  }

  /// Total plays for a game: BGG-reported plays plus any logged locally.
  int getPlayCount(int gameId) {
    final remote = _playsData[gameId]?.totalPlays ?? 0;
    final local = _playLog?.playCount(gameId) ?? 0;
    return remote + local;
  }

  bool isUnplayed(int gameId) => getPlayCount(gameId) == 0;

  bool isInCollection(int gameId) => _collectionGameIds.contains(gameId);

  Future<void>? _loadPlaysInFlight;
  final RetryScheduler _playsRetry = RetryScheduler();

  String? _analyticsSeededFor;
  String? _analyticsSeedTarget;
  bool _analyticsSeedInFlight = false;
  int _analyticsSeedAttempts = 0;
  final RetryScheduler _analyticsRetry = RetryScheduler();

  CollectionAnalytics? _collectionAnalytics;

  /// Latest collection analytics once fetched, or null while not-ready/failed.
  /// Drives quick-filter enhancements that degrade gracefully when absent.
  CollectionAnalytics? get collectionAnalytics => _collectionAnalytics;

  CollectionSummary? get collectionSummary => _collectionAnalytics?.summary;

  List<MechanicCount> get topMechanics =>
      _collectionAnalytics?.topMechanics ?? const [];

  List<PlayerCountCoverage> get playerCountCoverage =>
      _collectionAnalytics?.playerCountCoverage ?? const [];

  List<DistributionBucket> get complexityDistribution =>
      _collectionAnalytics?.complexityDistribution ?? const [];

  List<DistributionBucket> get playtimeDistribution =>
      _collectionAnalytics?.playtimeDistribution ?? const [];

  @visibleForTesting
  void setCollectionAnalyticsForTest(CollectionAnalytics? analytics) {
    _collectionAnalytics = analytics;
    notifyListeners();
  }

  @visibleForTesting
  void setGamesForTest(Games games) {
    _bggCache = BggCache(games, _defaultCacheDurationInMinutes);
    notifyListeners();
  }

  static const int _maxAnalyticsSeedAttempts = 5;

  /// Base retry delay (seconds), scaled by attempt for linear backoff.
  /// Overridable so tests drive retries without real waits.
  @visibleForTesting
  static int analyticsRetryDelaySeconds = 3;

  /// Completes when the latest seed attempt finishes. Test seam.
  @visibleForTesting
  Future<void>? analyticsSeedFuture;

  Future<void> loadPlays() {
    if (_primaryPlayer == null) return Future.value();
    analyticsSeedFuture = _seedFiltersFromAnalytics(_primaryPlayer!);
    return _loadPlaysInFlight ??= _doLoadPlays();
  }

  // Analytics compute async; early requests can be not-ready (non-200, or an
  // empty 200). Retry (bounded), marking seeded only once usable data arrives.
  Future<void> _seedFiltersFromAnalytics(String username) async {
    if (_analyticsSeededFor == username) return;
    if (username != _analyticsSeedTarget) {
      _analyticsSeedTarget = username;
      _analyticsSeedAttempts = 0;
      _analyticsRetry.cancel();
    } else if (_analyticsSeedInFlight || _analyticsRetry.isActive) {
      return;
    }
    _analyticsSeedInFlight = true;
    try {
      final result = await CollectionAnalyticsService.fetch(username);
      if (_disposed) return;
      final analytics = result.analytics;
      if (analytics != null && analytics.hasData) {
        _analyticsSeededFor = username;
        _collectionAnalytics = analytics;
        _analyticsRetry.cancel();
        FilterSeeder.seed(analytics, _settings);
        notifyListeners();
        return;
      }
      if (result.retryable) _scheduleAnalyticsSeedRetry(username);
    } finally {
      _analyticsSeedInFlight = false;
    }
  }

  void _scheduleAnalyticsSeedRetry(String username) {
    if (_analyticsSeedAttempts >= _maxAnalyticsSeedAttempts) return;
    _analyticsSeedAttempts++;
    _analyticsRetry.schedule(
      Duration(seconds: analyticsRetryDelaySeconds * _analyticsSeedAttempts),
      () {
        if (_disposed || _analyticsSeededFor == username) return;
        analyticsSeedFuture = _seedFiltersFromAnalytics(username);
      },
    );
  }

  Future<void> _doLoadPlays() async {
    try {
      final results = await Future.wait([
        PlaysService.fetchPlays(_primaryPlayer!),
        _fetchCollection(_primaryPlayer!),
      ]);
      final playsResult = results[0] as PlaysResult;
      final collection = results[1] as List<dynamic>;
      _playsData = playsResult.plays;
      _collectionGameIds = collection.map<int>((g) => g['id'] as int).toSet();
      _collectionThumbnails = {
        for (final g in collection)
          if (g['thumbnail'] != null) g['id'] as int: g['thumbnail'] as String,
      };
      _playsLoaded = true;
      notifyListeners();

      if (!playsResult.complete) {
        _schedulePlaysRetry(playsResult.retryAfterSeconds);
      }
    } finally {
      _loadPlaysInFlight = null;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _playsRetry.cancel();
    _analyticsRetry.cancel();
    // Flush any pending debounced write so a change made just before the user
    // navigates away is not lost.
    if (_storeDebounceTimer?.isActive ?? false) {
      _flushStore();
    }
    _playLog?.removeListener(_onPlayLogChanged);
    super.dispose();
  }

  void _schedulePlaysRetry(int delaySeconds) {
    final seconds = delaySeconds > 0 ? delaySeconds : 30;
    _playsRetry.schedule(Duration(seconds: seconds), () {
      PlaysService.clearCache();
      loadPlays();
    });
  }

  Future<List<dynamic>> _fetchCollection(String username) async {
    final url = Uri.parse(
      '${AppCommon.boardGameGeekProxyUrl}/collection/${Uri.encodeComponent(username)}',
    );
    final headers = {
      Settings.fieldsToReturnFromApi.header!: Settings
          .fieldsToReturnFromApi
          .value
          .toString(),
    };
    final response = await HttpRetryClient.getWithRetry(url, headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    return const [];
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

  final UrlFragmentExtractor _extractor;

  AppModel({
    PreferencesHistoryInterface? preferencesHistory,
    UrlFragmentExtractor? urlExtractor,
  }) : _preferencesHistory =
           preferencesHistory ?? StorageFactory.getPreferencesHistory(),
       _extractor = urlExtractor ?? UrlFragmentExtractor(Uri.base) {
    _settings = Settings.defaultSettings();
  }

  Future<void> refreshFromUrl() async {
    await _consumeUrlModel();
  }

  /// Applies items and settings encoded in the URL fragment, if any, exactly
  /// once. Safe to call from any entry point (home pages or a deep-linked
  /// list/random/detail page) and idempotent thereafter.
  Future<void> _consumeUrlModel() async {
    if (_urlConsumed) return;
    if (!_extractor.containsModel()) return;
    _urlConsumed = true;
    await _deferPastCurrentBuild();
    await replaceItems(_extractor.extractItems());
    var extractedSettings = _extractor.extractSettings();
    extractedSettings = _rebuildUrlMechanics(extractedSettings);
    if (_settings != extractedSettings) {
      _settings.updateAllSettings(extractedSettings);
      invalidateCache();
    }
  }

  /// The bootstrap methods run inside a widget build (the home pages call them
  /// from a Consumer builder), so the notifyListeners() that follows would
  /// otherwise fire during that build. Yielding to a microtask lets the current
  /// build complete first.
  Future<void> _deferPastCurrentBuild() => Future<void>.microtask(() {});

  Settings _rebuildUrlMechanics(Settings extractedSettings) {
    final mechanicsSetting = extractedSettings.setting(
      Settings.filterMechanics.name,
    );
    mechanicsSetting.value = mechanicsSetting.getList();
    return extractedSettings;
  }

  void toggleSortDirection() {
    sortDirection = sortDirection == SortOrder.Asc
        ? SortOrder.Desc
        : SortOrder.Asc;
  }

  Future<void> addItem(Item item) async {
    _items.itemList.add(item);
    final establishedPrimary =
        item.itemType == ItemType.collection && _primaryPlayer == null;
    if (establishedPrimary) {
      _primaryPlayer = item.name;
      _persistPrimaryPlayer();
    }
    invalidateCache();
    await updateStore();
    // New primary player: seed filter defaults now, not on the next refresh.
    // Plays load separately via PlaysLoadingIndicator.
    if (establishedPrimary) {
      analyticsSeedFuture = _seedFiltersFromAnalytics(item.name);
    }
  }

  Future<void> replaceItems(Items items) async {
    if (items == _items) {
      return;
    }
    _items = items;
    _reconcilePrimaryPlayer();
    invalidateCache();
    await updateStore();
  }

  /// Keeps [primaryPlayer] consistent with the current collection items after
  /// the item list is swapped wholesale (e.g. following a shared permalink or
  /// searching a different collection). If the existing primary player is no
  /// longer among the collections, it falls back to the first collection in
  /// the new list, or null when none remain. Going through the setter clears
  /// the stale plays/collection data and reloads for the new player.
  void _reconcilePrimaryPlayer() {
    final collections = _items.itemList
        .where((i) => i.itemType == ItemType.collection)
        .toList();
    final stillPresent =
        _primaryPlayer != null &&
        collections.any((i) => i.name == _primaryPlayer);
    if (stillPresent) return;
    primaryPlayer = collections.isNotEmpty ? collections.first.name : null;
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

  /// The pool for a game night ignores the per-game duration filters: the
  /// evening budget governs playtime, so the planner needs the short fillers
  /// and long centrepieces those filters would otherwise exclude. All other
  /// filters (players, mechanics, rating, complexity) still apply.
  GameRequest buildGameNightRequest() {
    final settings = _settings.clone();
    for (final name in [
      Settings.filterMinimumTimeToPlay.name,
      Settings.filterMaximumTimeToPlay.name,
    ]) {
      final disabled = settings.setting(name).clone()..enabled = false;
      settings.updateSetting(disabled);
    }
    return GameRequest.from(settings, _items);
  }

  /// A clone of the current settings tuned for a shareable Game Night link:
  /// Game Night mode on and the chosen [lineup] encoded, so a recipient lands
  /// on the same collection, evening length, and exact games. The live settings
  /// are untouched - the clone only shapes the permalink.
  Settings gameNightPermalinkSettings(GameNightLineup lineup) {
    final settings = _settings.clone();
    final mode = settings.setting(Settings.gameNightMode.name).clone()
      ..value = true
      ..enabled = true;
    settings.updateSetting(mode);
    final encodedLineup =
        settings.setting(Settings.gameNightLineup.name).clone()
          ..value = GameNightPermalink.encode(lineup)
          ..enabled = true;
    settings.updateSetting(encodedLineup);
    return settings;
  }

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
      _primaryPlayer = nextCollection.isNotEmpty
          ? nextCollection.first.name
          : null;
      _persistPrimaryPlayer();
    }
    invalidateCache();
    await _storeItems(_items);
  }

  Timer? _storeDebounceTimer;

  /// Delay before a debounced [updateStoreDebounced] actually persists.
  /// Dragging a slider fires many calls in quick succession; only the value the
  /// user settles on is written, once the drag pauses for this long.
  @visibleForTesting
  static Duration storeDebounceDelay = const Duration(milliseconds: 300);

  /// Number of times settings/items were actually persisted. A test hook to
  /// assert debouncing collapses a burst of calls into a single write.
  @visibleForTesting
  int storeWriteCount = 0;

  Future<void> updateStore() async {
    _storeDebounceTimer?.cancel();
    _storeDebounceTimer = null;
    await _flushStore();
    notifyListeners();
  }

  /// Like [updateStore] but for high-frequency callers such as slider drags:
  /// updates the UI immediately while collapsing the burst of writes into a
  /// single persistence after the user settles ([storeDebounceDelay]). A
  /// pending write is flushed on [dispose] so nothing is lost.
  void updateStoreDebounced() {
    notifyListeners();
    _storeDebounceTimer?.cancel();
    _storeDebounceTimer = Timer(storeDebounceDelay, _flushStore);
  }

  Future<void> _flushStore() async {
    _storeDebounceTimer?.cancel();
    _storeDebounceTimer = null;
    storeWriteCount++;
    await Future.wait([_storeSettings(settings), _storeItems(_items)]);
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
      // A shared/deep link encodes the model in the URL fragment. Apply it here
      // so the parameters survive a hard refresh onto any page, not just the
      // home pages that separately call refreshFromUrl(). The primary player is
      // derived from the permalink's collections by replaceItems - the stored
      // one belongs to a previous session and must not clobber it.
      await _consumeUrlModel();
      hasLoadedPersistedData = true;
    } else {
      final store = await _getStore();
      _items = await store.loadItems(AppCommon.maxItemsFromBgg);
      replaceSettings(await store.loadSettings(settings));
      hasLoadedPersistedData = true;

      final prefs = await SharedPreferences.getInstance();
      _primaryPlayer = prefs.getString('primary_player');
      // Enforce the invariant that a set collection always has a primary
      // player: on refresh the stored value may be missing or stale (a
      // collection removed in a prior session), which would leave no crown
      // icon. Fall back to the first collection in the list.
      _reconcilePrimaryPlayer();
    }

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
