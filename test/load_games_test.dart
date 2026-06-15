import 'package:how_many_mobile_meeple/load_games.dart';
import 'package:how_many_mobile_meeple/model/game_request.dart';
import 'package:how_many_mobile_meeple/model/item.dart';
import 'package:how_many_mobile_meeple/model/items.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';
import 'package:test/test.dart';

void main() {
  group('LoadGames.fetchGames', () {
    test('handles empty items list', () async {
      final request = GameRequest.from(Settings.defaultSettings(), Items([]));

      final games = await LoadGames.fetchGames(request);

      expect(games.games, isEmpty);
    });

    test('handles single item', () async {
      final request = GameRequest.from(
          Settings.defaultSettings(), Items([Item('testuser')]));

      expect(() => LoadGames.fetchGames(request), returnsNormally);
    });

    test('handles multiple items for parallel processing', () async {
      final request = GameRequest.from(
        Settings.defaultSettings(),
        Items([Item('testuser1'), Item('testuser2'), Item('testuser3')]),
      );

      expect(() => LoadGames.fetchGames(request), returnsNormally);
    });
  });

  group('GameRequest geeklist routing', () {
    test('geeklist item type name is the geeklist URL path segment', () {
      expect(ItemType.geekList.name, 'geeklist');
    });

    test('collection item type name is the collection URL path segment', () {
      expect(ItemType.collection.name, 'collection');
    });

    test('GameRequest preserves geeklist item type', () {
      final item = Item('12345');
      final request =
          GameRequest.from(Settings.defaultSettings(), Items([item]));

      expect(request.items.itemList.first.itemType, ItemType.geekList);
    });

    test('GameRequest preserves collection item type', () {
      final item = Item('testuser');
      final request =
          GameRequest.from(Settings.defaultSettings(), Items([item]));

      expect(request.items.itemList.first.itemType, ItemType.collection);
    });

    test('GameRequest with mixed items preserves each item type', () {
      final geeklist = Item('12345');
      final collection = Item('testuser');
      final request = GameRequest.from(
          Settings.defaultSettings(), Items([geeklist, collection]));

      expect(request.items.itemList[0].itemType, ItemType.geekList);
      expect(request.items.itemList[1].itemType, ItemType.collection);
    });

    test('two requests with same geeklist are equal', () {
      final r1 =
          GameRequest.from(Settings.defaultSettings(), Items([Item('12345')]));
      final r2 =
          GameRequest.from(Settings.defaultSettings(), Items([Item('12345')]));

      expect(r1, equals(r2));
    });

    test('geeklist and collection requests with same name are not equal', () {
      final r1 = GameRequest.from(Settings.defaultSettings(),
          Items([Item('12345', itemType: ItemType.geekList)]));
      final r2 = GameRequest.from(Settings.defaultSettings(),
          Items([Item('12345', itemType: ItemType.collection)]));

      expect(r1, isNot(equals(r2)));
    });
  });
}
