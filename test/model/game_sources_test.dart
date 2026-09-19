@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:how_many_mobile_meeple/model/game.dart';
import 'package:how_many_mobile_meeple/model/game_sources.dart';
import 'package:how_many_mobile_meeple/model/item.dart';

Game _game(int id) => Game(
  id: id,
  name: 'Game $id',
  maxPlayers: 4,
  minPlayers: 2,
  maxPlaytime: 60,
  imageUrl: '',
  averageRating: 7,
  averageWeight: 2.5,
);

void main() {
  group('GameSources', () {
    test('maps a game to the collection it came from', () {
      final teqqles = Item('teqqles', itemType: ItemType.collection);
      final sources = GameSources.fromSources([
        (item: teqqles, games: [_game(1), _game(2)]),
      ]);

      expect(sources.sourceFor(1), teqqles);
      expect(sources.sourceFor(2), teqqles);
    });

    test('returns null for a game in no source', () {
      final sources = GameSources.fromSources([
        (
          item: Item('teqqles', itemType: ItemType.collection),
          games: [_game(1)],
        ),
      ]);

      expect(sources.sourceFor(999), isNull);
    });

    test('prefers a collection over a geeklist when a game is in both', () {
      final geeklist = Item('12345', itemType: ItemType.geekList);
      final collection = Item('teqqles', itemType: ItemType.collection);
      // Geeklist added first, but the collection must still win.
      final sources = GameSources.fromSources([
        (item: geeklist, games: [_game(1)]),
        (item: collection, games: [_game(1)]),
      ]);

      expect(sources.sourceFor(1), collection);
    });

    test('breaks a same-type tie by add order (first added wins)', () {
      final first = Item('alice', itemType: ItemType.collection);
      final second = Item('bob', itemType: ItemType.collection);
      final sources = GameSources.fromSources([
        (item: first, games: [_game(1)]),
        (item: second, games: [_game(1)]),
      ]);

      expect(sources.sourceFor(1), first);
    });

    test('excludes hotlist sources', () {
      final sources = GameSources.fromSources([
        (item: Item('trending', itemType: ItemType.hotList), games: [_game(1)]),
      ]);

      expect(sources.sourceFor(1), isNull);
    });

    test('falls back to a geeklist when no collection holds the game', () {
      final geeklist = Item('12345', itemType: ItemType.geekList);
      final sources = GameSources.fromSources([
        (
          item: Item('teqqles', itemType: ItemType.collection),
          games: [_game(2)],
        ),
        (item: geeklist, games: [_game(1)]),
      ]);

      expect(sources.sourceFor(1), geeklist);
    });

    test('empty has no sources', () {
      expect(const GameSources.empty().sourceFor(1), isNull);
    });
  });
}
