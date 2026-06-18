import 'package:flutter_test/flutter_test.dart';
import 'package:how_many_mobile_meeple/model/game_request.dart';
import 'package:how_many_mobile_meeple/model/item.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppModel.replaceCache stale-response guard', () {
    test('accepts response when request matches current model state', () {
      final model = AppModel()..hasLoadedPersistedData = true;
      model.items.itemList.add(Item('teqqles'));

      final request = model.buildRequest();
      final games = TestHelpers.twoGames();

      model.invalidateCache();
      model.replaceCache(games, request);

      expect(model.bggCache.isStale(), false);
      expect(model.bggCache.games, games);
    });

    test(
        'rejects response when items have changed since fetch started - '
        'simulates background fetcher refilling cache after deleteItem', () {
      final model = AppModel()..hasLoadedPersistedData = true;
      // Setup: two items
      model.items.itemList.add(Item('teqqles'));
      model.items.itemList.add(Item('dragonc'));

      // Fetch was kicked off with teqqles+dragonc
      final staleRequest = model.buildRequest();
      final staleGames = TestHelpers.twoGames();

      // User removes dragonc - cache becomes stale, items shrink to [teqqles]
      model.items.itemList.remove(Item('dragonc'));
      model.invalidateCache();

      // Stale fetch completes and tries to fill the cache
      model.replaceCache(staleGames, staleRequest);

      // Cache must remain stale - stale response was rejected
      expect(model.bggCache.isStale(), true,
          reason: 'stale response from old items set must be rejected');
    });

    test(
        'rejects response when headers have changed since fetch started - '
        'simulates in-flight fetch completing after a filter change', () {
      final model = AppModel()..hasLoadedPersistedData = true;
      model.items.itemList.add(Item('teqqles'));

      // Fetch was kicked off with player count = 8
      final settingsAt8Players = Settings.defaultSettings();
      settingsAt8Players.setting(Settings.filterNumberOfPlayers.name).value =
          '8';
      settingsAt8Players.setting(Settings.filterNumberOfPlayers.name).enabled =
          true;
      final staleRequest = GameRequest.from(
        settingsAt8Players,
        model.items,
      );
      final staleGames = TestHelpers.twoGames();

      // User changes player count to 6
      model.settings.setting(Settings.filterNumberOfPlayers.name).value = '6';
      model.settings.setting(Settings.filterNumberOfPlayers.name).enabled =
          true;
      model.invalidateCache();

      // In-flight fetch for player=8 completes
      model.replaceCache(staleGames, staleRequest);

      expect(model.bggCache.isStale(), true,
          reason: 'stale response with old headers must be rejected');
    });

    test(
        'accepts fresh response after deleteItem invalidates and new fetch '
        'completes with updated items', () {
      final model = AppModel()..hasLoadedPersistedData = true;
      model.items.itemList.add(Item('teqqles'));
      model.items.itemList.add(Item('dragonc'));

      model.items.itemList.remove(Item('dragonc'));
      model.invalidateCache();

      // New fetch completes with only teqqles
      final freshRequest = model.buildRequest();
      final freshGames = TestHelpers.oneGame();

      model.replaceCache(freshGames, freshRequest);

      expect(model.bggCache.isStale(), false);
      expect(model.bggCache.games, freshGames);
    });
  });
}
