@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:how_many_mobile_meeple/recently_viewed/recently_viewed_game.dart';
import 'package:how_many_mobile_meeple/recently_viewed/recently_viewed_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    RecentlyViewedService.resetForTesting();
    SharedPreferences.setMockInitialValues({});
  });

  RecentlyViewedGame game(int id) =>
      RecentlyViewedGame(id: id, name: 'Game $id', thumbnail: 'thumb$id');

  group('RecentlyViewedService', () {
    test('starts empty', () async {
      final service = await RecentlyViewedService.instance();
      expect(service.games, isEmpty);
    });

    test('add inserts the game at the front', () async {
      final service = await RecentlyViewedService.instance();
      service.add(game(1));
      service.add(game(2));
      expect(service.games.map((g) => g.id), [2, 1]);
    });

    test('viewing a game again moves it to the front without duplicating',
        () async {
      final service = await RecentlyViewedService.instance();
      service.add(game(1));
      service.add(game(2));
      service.add(game(3));
      service.add(game(1));
      expect(service.games.map((g) => g.id), [1, 3, 2]);
    });

    test('re-adding the current most-recent game is a no-op', () async {
      final service = await RecentlyViewedService.instance();
      service.add(game(1));

      var notified = false;
      service.addListener(() => notified = true);
      service.add(game(1));

      expect(notified, isFalse,
          reason: 're-viewing the front game must not notify or reorder');
      expect(service.games.map((g) => g.id), [1]);
    });

    test('caps the history at 10 entries, dropping the oldest', () async {
      final service = await RecentlyViewedService.instance();
      for (var i = 1; i <= 12; i++) {
        service.add(game(i));
      }
      expect(service.games.length, 10);
      // Most recent first; ids 1 and 2 (oldest) have dropped off.
      expect(service.games.first.id, 12);
      expect(service.games.map((g) => g.id), isNot(contains(1)));
      expect(service.games.map((g) => g.id), isNot(contains(2)));
    });

    test('notifies listeners when a new game is added', () async {
      final service = await RecentlyViewedService.instance();
      var notified = false;
      service.addListener(() => notified = true);
      service.add(game(1));
      expect(notified, isTrue);
    });

    test('persists games to SharedPreferences', () async {
      final service = await RecentlyViewedService.instance();
      service.add(game(1));

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('recently_viewed_games');
      expect(raw, isNotNull);
      expect(raw, contains('Game 1'));
    });

    test('loads persisted games on init', () async {
      SharedPreferences.setMockInitialValues({
        'recently_viewed_games':
            '[{"id":7,"name":"Catan","thumbnail":"t"},{"id":8,"name":"Root","thumbnail":null}]',
      });

      final service = await RecentlyViewedService.instance();
      expect(service.games.map((g) => g.id), [7, 8]);
      expect(service.games.first.name, 'Catan');
      expect(service.games.last.thumbnail, isNull);
    });
  });
}
