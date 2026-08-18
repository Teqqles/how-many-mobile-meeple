@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:how_many_mobile_meeple/model/game.dart';
import 'package:how_many_mobile_meeple/model/game_night.dart';

Game _game(
  int id,
  int maxPlaytime, {
  double weight = 2.5,
  String? name,
  List<String> mechanics = const [],
}) => Game(
  id: id,
  name: name ?? 'Game $id',
  maxPlayers: 4,
  minPlayers: 2,
  maxPlaytime: maxPlaytime,
  imageUrl: '',
  averageRating: 7,
  averageWeight: weight,
  mechanics: mechanics,
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

    test('a 45-minute game still qualifies as a filler', () {
      final lineup = _planner().plan(
        pool: [_game(1, 45), _game(2, 90)],
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

    test('a slot mechanic narrows that slot to matching games', () {
      final lineup = _planner().plan(
        pool: [
          _game(1, 120, mechanics: ['Worker Placement']),
          _game(2, 118, mechanics: ['Dice Rolling']),
          _game(3, 15),
        ],
        durationMinutes: 240,
        slotMechanics: {GameNightSlot.main: 'Dice Rolling'},
      );

      // Both long games fit, but only game 2 carries the chosen mechanic.
      expect(lineup.main!.id, 2);
    });

    test('a slot with no mechanic match is left empty', () {
      final lineup = _planner().plan(
        pool: [
          _game(1, 15),
          _game(2, 120, mechanics: ['Worker Placement']),
        ],
        durationMinutes: 240,
        slotMechanics: {GameNightSlot.main: 'Legacy Game'},
      );

      expect(lineup.filler!.id, 1);
      expect(lineup.main, isNull);
    });

    test('mechanic on one slot does not constrain the others', () {
      final lineup = _planner().plan(
        pool: [
          _game(1, 15, mechanics: ['Dice Rolling']),
          _game(2, 120, mechanics: ['Worker Placement']),
        ],
        durationMinutes: 240,
        slotMechanics: {GameNightSlot.filler: 'Dice Rolling'},
      );

      expect(lineup.filler!.id, 1);
      expect(lineup.main!.id, 2); // unconstrained slot still fills
    });

    test('reserves setup and teardown overhead against the budget', () {
      // A 90-min heavy game costs 90 + 15 overhead = 105. With a 15-min light
      // filler costing 15 + 5 = 20, the pair needs 125 minutes.
      final justFits = _planner().plan(
        pool: [_game(1, 15, weight: 1.5), _game(2, 90, weight: 3.5)],
        durationMinutes: 125,
      );
      expect(justFits.main!.id, 2);

      final justShort = _planner().plan(
        pool: [_game(1, 15, weight: 1.5), _game(2, 90, weight: 3.5)],
        durationMinutes: 124,
      );
      expect(justShort.main, isNull); // one minute short once overhead counts
    });

    test('weights a favourite into extra draw slots', () {
      // Two equally valid mains; index 1 of the raw list is game 2, but game 1
      // is a favourite, so its repeats push game 2 down the weighted list.
      final lineup = GameNightPlanner(pick: (count) => count > 1 ? 1 : 0).plan(
        pool: [_game(1, 120), _game(2, 118)],
        durationMinutes: 240,
        favouriteIds: {1},
      );

      expect(lineup.main!.id, 1);
    });

    test('a favourite never crowds out the rest of the pool', () {
      // The last weighted slot still belongs to the non-favourite, so it can
      // win when the draw lands there.
      final lineup = GameNightPlanner(pick: (count) => count - 1).plan(
        pool: [_game(1, 120), _game(2, 118)],
        durationMinutes: 240,
        favouriteIds: {1},
      );

      expect(lineup.main!.id, 2);
    });

    test('adds a wind-down outro on a long night with time to spare', () {
      final lineup = _planner().plan(
        pool: [_game(1, 15), _game(2, 120), _game(3, 20)],
        durationMinutes: 240,
      );

      // Filler 15 + main 120 leaves 105 minutes, so the short game closes out.
      expect(lineup.main!.id, 2);
      expect(lineup.outro!.id, 3);
    });

    test('no outro on a short night', () {
      final lineup = _planner().plan(
        pool: [_game(1, 15), _game(2, 90), _game(3, 20)],
        durationMinutes: 120,
      );

      expect(lineup.outro, isNull);
    });

    test('no outro when the main leaves no room for a closer', () {
      final lineup = _planner().plan(
        pool: [_game(1, 15), _game(2, 120), _game(3, 20)],
        durationMinutes: 160,
      );

      // Filler cost 25 + main cost 130 = 155, leaving 5 minutes - far short of
      // the cheapest closer (a 20-min game costs 30 with its overhead).
      expect(lineup.main!.id, 2);
      expect(lineup.outro, isNull);
    });

    test('includeOutro false suppresses the closer', () {
      final lineup = _planner().plan(
        pool: [_game(1, 15), _game(2, 120), _game(3, 20)],
        durationMinutes: 240,
        includeOutro: false,
      );

      expect(lineup.outro, isNull);
    });

    test('a pinned outro is kept and never reused elsewhere', () {
      final pinnedOutro = _game(3, 20);
      final lineup = _planner().plan(
        pool: [_game(1, 15), _game(2, 120), pinnedOutro],
        durationMinutes: 240,
        pinned: {GameNightSlot.outro: pinnedOutro},
      );

      expect(lineup.outro!.id, 3);
      expect(lineup.filler?.id, isNot(3));
    });
  });

  group('GameNightPermalink', () {
    test('round-trips a full lineup by slot', () {
      final lineup = GameNightLineup(
        filler: _game(12, 20),
        main: _game(45, 90),
        backup: _game(7, 80),
        outro: _game(8, 25),
      );

      final decoded = GameNightPermalink.decode(
        GameNightPermalink.encode(lineup),
      );

      expect(decoded, {
        GameNightSlot.filler: 12,
        GameNightSlot.main: 45,
        GameNightSlot.backup: 7,
        GameNightSlot.outro: 8,
      });
    });

    test('encodes an empty slot as zero and drops it on decode', () {
      final lineup = GameNightLineup(main: _game(45, 90));

      final token = GameNightPermalink.encode(lineup);
      expect(token, '0-45-0-0');
      expect(GameNightPermalink.decode(token), {GameNightSlot.main: 45});
    });

    test('a malformed token yields no pins', () {
      expect(GameNightPermalink.decode('nonsense'), isEmpty);
      expect(GameNightPermalink.decode('1-2-3'), isEmpty);
    });
  });
}
