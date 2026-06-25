import 'package:flutter_test/flutter_test.dart';
import 'package:how_many_mobile_meeple/favourites/favourite_game.dart';
import 'package:how_many_mobile_meeple/favourites/favourites_service.dart';
import 'package:how_many_mobile_meeple/favourites/ignored_games_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FavouritesService.resetForTesting();
    IgnoredGamesService.resetForTesting();
    SharedPreferences.setMockInitialValues({});
  });

  final game1 = FavouriteGame(id: 1, name: 'Catan', thumbnail: null);
  final game2 = FavouriteGame(id: 2, name: 'Pandemic', thumbnail: null);
  final game3 = FavouriteGame(id: 3, name: 'Wingspan', thumbnail: null);

  group('FavouritesService', () {
    test('starts empty', () async {
      final service = await FavouritesService.instance();
      expect(service.games, isEmpty);
    });

    test('toggle adds a game', () async {
      final service = await FavouritesService.instance();
      service.toggle(game1);
      expect(service.contains(1), isTrue);
      expect(service.games.length, 1);
    });

    test('toggle removes a game that is already added', () async {
      final service = await FavouritesService.instance();
      service.toggle(game1);
      service.toggle(game1);
      expect(service.contains(1), isFalse);
      expect(service.games, isEmpty);
    });

    test('remove removes a game by id', () async {
      final service = await FavouritesService.instance();
      service.toggle(game1);
      service.toggle(game2);
      service.remove(1);
      expect(service.contains(1), isFalse);
      expect(service.contains(2), isTrue);
    });

    test('contains returns false for unknown id', () async {
      final service = await FavouritesService.instance();
      expect(service.contains(999), isFalse);
    });

    test('new games are inserted at the front', () async {
      final service = await FavouritesService.instance();
      service.toggle(game1);
      service.toggle(game2);
      expect(service.games.first.id, 2);
    });

    test('notifies listeners on toggle', () async {
      final service = await FavouritesService.instance();
      var notified = false;
      service.addListener(() => notified = true);
      service.toggle(game1);
      expect(notified, isTrue);
    });

    test('notifies listeners on remove', () async {
      final service = await FavouritesService.instance();
      service.toggle(game1);
      var notified = false;
      service.addListener(() => notified = true);
      service.remove(1);
      expect(notified, isTrue);
    });
  });

  group('IgnoredGamesService', () {
    test('starts empty', () async {
      final service = await IgnoredGamesService.instance();
      expect(service.games, isEmpty);
    });

    test('toggle adds a game', () async {
      final service = await IgnoredGamesService.instance();
      service.toggle(game3);
      expect(service.contains(3), isTrue);
    });

    test('toggle removes a game that is already added', () async {
      final service = await IgnoredGamesService.instance();
      service.toggle(game3);
      service.toggle(game3);
      expect(service.contains(3), isFalse);
    });
  });

  group('mutual exclusivity', () {
    test('adding to favourites removes from ignored', () async {
      final favs = await FavouritesService.instance();
      final ignored = await IgnoredGamesService.instance();

      ignored.toggle(game1);
      expect(ignored.contains(1), isTrue);

      favs.toggle(game1);
      expect(favs.contains(1), isTrue);
      expect(ignored.contains(1), isFalse);
    });

    test('adding to ignored removes from favourites', () async {
      final favs = await FavouritesService.instance();
      final ignored = await IgnoredGamesService.instance();

      favs.toggle(game2);
      expect(favs.contains(2), isTrue);

      ignored.toggle(game2);
      expect(ignored.contains(2), isTrue);
      expect(favs.contains(2), isFalse);
    });

    test('toggling off does not affect the other list', () async {
      final favs = await FavouritesService.instance();
      final ignored = await IgnoredGamesService.instance();

      favs.toggle(game1);
      favs.toggle(game1);
      expect(favs.contains(1), isFalse);
      expect(ignored.contains(1), isFalse);
    });
  });

  group('persistence', () {
    test('saves games to SharedPreferences', () async {
      final service = await FavouritesService.instance();
      service.toggle(game1);
      service.toggle(game2);

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('favourite_games');
      expect(raw, isNotNull);
      expect(raw, contains('Catan'));
      expect(raw, contains('Pandemic'));
    });

    test('loads persisted games on init', () async {
      SharedPreferences.setMockInitialValues({
        'favourite_games': '[{"id":1,"name":"Catan","thumbnail":null}]',
      });

      final service = await FavouritesService.instance();
      expect(service.contains(1), isTrue);
      expect(service.games.length, 1);
    });
  });
}
