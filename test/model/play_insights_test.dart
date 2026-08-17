import 'package:flutter_test/flutter_test.dart';
import 'package:how_many_mobile_meeple/model/play_data.dart';
import 'package:how_many_mobile_meeple/model/play_insights.dart';

PlayData _data(
  int id,
  String name,
  int totalPlays, {
  List<BggPlay> plays = const [],
}) =>
    PlayData(gameId: id, gameName: name, totalPlays: totalPlays, plays: plays);

void main() {
  group('PlayInsights.from', () {
    test('splits played vs unplayed by play count', () {
      final stats = PlayInsights.from(
        collectionGameIds: {1, 2, 3},
        playsData: {1: _data(1, 'A', 3), 2: _data(2, 'B', 1)},
        playCount: (id) => {1: 3, 2: 1, 3: 0}[id]!,
        now: DateTime(2026),
      );

      expect(stats.totalGames, 3);
      expect(stats.playedGames, 2);
      expect(stats.unplayedGames, 1);
      expect(stats.totalPlays, 4);
    });

    test('counts played-once vs repeated', () {
      final stats = PlayInsights.from(
        collectionGameIds: {1, 2, 3},
        playsData: {},
        playCount: (id) => {1: 1, 2: 5, 3: 0}[id]!,
        now: DateTime(2026),
      );

      expect(stats.playedOnce, 1);
      expect(stats.playedRepeatedly, 1);
    });

    test('sums minutes and counts plays in the current year', () {
      final stats = PlayInsights.from(
        collectionGameIds: {1},
        playsData: {
          1: _data(
            1,
            'A',
            3,
            plays: [
              BggPlay(playId: 1, date: DateTime(2026, 3, 1), length: 60),
              BggPlay(playId: 2, date: DateTime(2025, 6, 1), length: 45),
              BggPlay(playId: 3, date: DateTime(2026, 9, 1), length: 30),
            ],
          ),
        },
        playCount: (id) => 3,
        now: DateTime(2026, 8, 17),
      );

      expect(stats.totalMinutes, 135);
      expect(stats.playsThisYear, 2);
    });

    test('ranks most played by plays desc then name asc, capped at topN', () {
      final stats = PlayInsights.from(
        collectionGameIds: {1, 2, 3},
        playsData: {
          1: _data(1, 'Zebra', 5),
          2: _data(2, 'Apple', 5),
          3: _data(3, 'Cat', 2),
        },
        playCount: (id) => {1: 5, 2: 5, 3: 2}[id]!,
        now: DateTime(2026),
        topN: 2,
      );

      expect(stats.mostPlayed.length, 2);
      expect(stats.mostPlayed[0].name, 'Apple');
      expect(stats.mostPlayed[1].name, 'Zebra');
    });

    test('falls back to a placeholder name for games without play data', () {
      final stats = PlayInsights.from(
        collectionGameIds: {99},
        playsData: {},
        playCount: (id) => 2,
        now: DateTime(2026),
      );

      expect(stats.mostPlayed.single.name, 'Game #99');
    });

    test('aggregates plays per year, newest first', () {
      final stats = PlayInsights.from(
        collectionGameIds: {1},
        playsData: {
          1: _data(
            1,
            'A',
            4,
            plays: [
              BggPlay(playId: 1, date: DateTime(2024, 1, 1)),
              BggPlay(playId: 2, date: DateTime(2026, 1, 1)),
              BggPlay(playId: 3, date: DateTime(2024, 5, 1)),
              BggPlay(playId: 4, date: DateTime(2025, 1, 1)),
            ],
          ),
        },
        playCount: (id) => 4,
        now: DateTime(2026),
      );

      expect(stats.playsPerYear.map((y) => y.year).toList(), [
        2026,
        2025,
        2024,
      ]);
      expect(stats.playsPerYear.map((y) => y.plays).toList(), [1, 1, 2]);
      // All of game 1's plays are owned, so the collection subset matches.
      expect(stats.playsPerYear.map((y) => y.collectionPlays).toList(), [
        1,
        1,
        2,
      ]);
    });

    test('splits plays per year into collection vs all', () {
      final stats = PlayInsights.from(
        collectionGameIds: {1},
        playsData: {
          1: _data(
            1,
            'Owned',
            1,
            plays: [BggPlay(playId: 1, date: DateTime(2026, 1, 1))],
          ),
          2: _data(
            2,
            'Borrowed',
            2,
            plays: [
              BggPlay(playId: 2, date: DateTime(2026, 2, 1)),
              BggPlay(playId: 3, date: DateTime(2026, 3, 1)),
            ],
          ),
        },
        playCount: (id) => {1: 1, 2: 2}[id]!,
        now: DateTime(2026),
      );

      final year = stats.playsPerYear.single;
      expect(year.year, 2026);
      expect(year.plays, 3);
      expect(year.collectionPlays, 1);
    });

    test('counts plays outside the collection in activity and most played', () {
      final stats = PlayInsights.from(
        collectionGameIds: {1},
        playsData: {
          1: _data(
            1,
            'Owned',
            1,
            plays: [BggPlay(playId: 1, date: DateTime(2026), length: 60)],
          ),
          2: _data(
            2,
            'Borrowed',
            3,
            plays: [BggPlay(playId: 2, date: DateTime(2026), length: 90)],
          ),
        },
        playCount: (id) => {1: 1, 2: 3}[id]!,
        now: DateTime(2026),
      );

      // Minutes, plays and rankings span everything played...
      expect(stats.totalMinutes, 150);
      expect(stats.totalPlays, 4);
      expect(stats.playsThisYear, 2);
      expect(stats.mostPlayed.map((m) => m.name).toList(), [
        'Borrowed',
        'Owned',
      ]);
      // ...but backlog stays scoped to the owned collection.
      expect(stats.totalGames, 1);
      expect(stats.playedGames, 1);
      expect(stats.unplayedGames, 0);
    });

    test('hasPlays is false when nothing has been played', () {
      final stats = PlayInsights.from(
        collectionGameIds: {1, 2},
        playsData: {},
        playCount: (id) => 0,
        now: DateTime(2026),
      );

      expect(stats.hasPlays, isFalse);
      expect(stats.playedGames, 0);
    });
  });
}
