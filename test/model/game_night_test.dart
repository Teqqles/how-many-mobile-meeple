@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:how_many_mobile_meeple/model/game.dart';
import 'package:how_many_mobile_meeple/model/game_night.dart';

Game _game(int id, int maxPlaytime, {double weight = 2.5, String? name}) =>
    Game(
      id: id,
      name: name ?? 'Game $id',
      maxPlayers: 4,
      minPlayers: 2,
      maxPlaytime: maxPlaytime,
      imageUrl: '',
      averageRating: 7,
      averageWeight: weight,
    );

// Always pick the first candidate so slot selection is deterministic.
GameNightPlanner _planner() => GameNightPlanner(pick: (_) => 0);

void main() {
  group('GameNightPlanner.plan', () {
    test('picks a short game for the filler slot', () {
      final lineup = _planner().plan(
        pool: [_game(1, 15), _game(2, 90)],
        durationMinutes: 180,
      );

      expect(lineup.filler!.id, 1);
    });

    test('picks the longest fitting game as the main', () {
      final lineup = _planner().plan(
        pool: [_game(1, 15), _game(2, 60), _game(3, 120), _game(4, 400)],
        durationMinutes: 180,
      );

      // 400 exceeds the budget (180 - 15 filler = 165), so 120 wins.
      expect(lineup.main!.id, 3);
    });

    test('varies the main among the longest fitting games on regenerate', () {
      final pool = [_game(1, 120), _game(2, 110), _game(3, 100), _game(4, 15)];

      // The filler is the only short game, so both planners pick it; the main
      // is chosen from the long games, and a different index yields a different
      // centrepiece.
      final first = GameNightPlanner(pick: (_) => 0)
          .plan(pool: pool, durationMinutes: 180);
      final second = GameNightPlanner(pick: (count) => count > 1 ? 1 : 0)
          .plan(pool: pool, durationMinutes: 180);

      expect(first.main!.id, isNot(second.main!.id));
    });

    test('keeps filler plus main within the budget', () {
      final lineup = _planner().plan(
        pool: [_game(1, 15), _game(2, 200)],
        durationMinutes: 120,
      );

      expect(lineup.filler!.id, 1);
      expect(lineup.main, isNull); // 200 > 120 - 15
    });

    test('backup differs from the main on complexity band', () {
      final lineup = _planner().plan(
        pool: [
          _game(1, 95, weight: 3.5), // heavy, longest - becomes main
          _game(2, 90, weight: 3.6), // heavy, similar time
          _game(3, 92, weight: 1.5), // light, similar time - preferred backup
        ],
        durationMinutes: 240,
      );

      expect(lineup.main!.id, 1);
      expect(lineup.backup!.id, 3);
    });

    test(
      'falls back to any similar-time game when no band contrast exists',
      () {
        final lineup = _planner().plan(
          pool: [_game(1, 90, weight: 3.5), _game(2, 85, weight: 3.6)],
          durationMinutes: 240,
        );

        expect(lineup.main!.id, 1);
        expect(lineup.backup!.id, 2);
      },
    );

    test('no backup when nothing shares the main playtime', () {
      final lineup = _planner().plan(
        pool: [_game(1, 90), _game(2, 20)],
        durationMinutes: 240,
      );

      expect(lineup.main!.id, 1);
      expect(lineup.backup, isNull); // 20 is outside the tolerance of 90
    });

    test('honours pinned slots and never reuses a pinned game', () {
      final pinnedMain = _game(3, 120);
      final lineup = _planner().plan(
        pool: [_game(1, 15), _game(2, 60), pinnedMain],
        durationMinutes: 180,
        pinned: {GameNightSlot.main: pinnedMain},
      );

      expect(lineup.main!.id, 3);
      expect(lineup.filler!.id, 1);
      expect(lineup.backup?.id, isNot(3));
    });

    test('empty pool yields an empty lineup', () {
      final lineup = _planner().plan(pool: [], durationMinutes: 180);
      expect(lineup.isEmpty, isTrue);
    });
  });

  group('GameNightPermalink', () {
    test('round-trips a full lineup by slot', () {
      final lineup = GameNightLineup(
        filler: _game(12, 20),
        main: _game(45, 90),
        backup: _game(7, 80),
      );

      final decoded = GameNightPermalink.decode(
        GameNightPermalink.encode(lineup),
      );

      expect(decoded, {
        GameNightSlot.filler: 12,
        GameNightSlot.main: 45,
        GameNightSlot.backup: 7,
      });
    });

    test('encodes an empty slot as zero and drops it on decode', () {
      final lineup = GameNightLineup(main: _game(45, 90));

      final token = GameNightPermalink.encode(lineup);
      expect(token, '0-45-0');
      expect(GameNightPermalink.decode(token), {GameNightSlot.main: 45});
    });

    test('a malformed token yields no pins', () {
      expect(GameNightPermalink.decode('nonsense'), isEmpty);
      expect(GameNightPermalink.decode('1-2'), isEmpty);
    });
  });
}
