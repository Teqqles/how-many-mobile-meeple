@Tags(['unit'])
library;

import 'package:how_many_mobile_meeple/model/bgg_cache.dart';
import 'package:how_many_mobile_meeple/model/game.dart';
import 'package:how_many_mobile_meeple/model/games.dart';
import 'package:test/test.dart';

main() {
  var duration = 1;
  var game1 = Game(
    id: 1,
    name: 'game1',
    maxPlayers: 4,
    minPlayers: 2,
    maxPlaytime: 60,
    imageUrl: 'http://example.com/game1.jpg',
    averageRating: 7.5,
    averageWeight: 2.5,
  );
  var game2 = Game(
    id: 2,
    name: 'game2',
    maxPlayers: 6,
    minPlayers: 2,
    maxPlaytime: 90,
    imageUrl: 'http://example.com/game2.jpg',
    averageRating: 8.0,
    averageWeight: 3.0,
  );
  var games = Games(gamesByName: {game1.name: game1, game2.name: game2});
  group('BggCache', () {
    test('contains a list of games with a cache duration', () {
      var cache = BggCache(games, duration);
      expect(cache.games, games);
      expect(cache.durationInMinutes, duration);
    });
  });
  group('isStale', () {
    test('returns false when the given duration is beyond the current time',
        () {
      var cache = BggCache(games, duration);
      expect(cache.isStale(), false);
    });
    test('returns true when the given duration is in the past', () {
      var cache = BggCache(games, -duration);
      expect(cache.isStale(), true);
    });
  });
  group('isStale with injectable clock', () {
    test('not stale when clock is before expiry', () {
      final baseTime = DateTime(2024, 1, 1, 12, 0, 0);
      var currentTime = baseTime;
      final cache = BggCache(games, 5, clock: () => currentTime);

      expect(cache.isStale(), false);

      // 4 minutes later — still fresh
      currentTime = baseTime.add(Duration(minutes: 4));
      expect(cache.isStale(), false);
    });

    test('stale exactly at expiry boundary', () {
      final baseTime = DateTime(2024, 1, 1, 12, 0, 0);
      var currentTime = baseTime;
      final cache = BggCache(games, 5, clock: () => currentTime);

      // 5 minutes later — at boundary
      currentTime = baseTime.add(Duration(minutes: 5));
      expect(cache.isStale(), false);

      // 5 minutes + 1 second — past boundary
      currentTime = baseTime.add(Duration(minutes: 5, seconds: 1));
      expect(cache.isStale(), true);
    });

    test('stale well after expiry', () {
      final baseTime = DateTime(2024, 1, 1, 12, 0, 0);
      var currentTime = baseTime;
      final cache = BggCache(games, 5, clock: () => currentTime);

      currentTime = baseTime.add(Duration(hours: 1));
      expect(cache.isStale(), true);
    });

    test('refreshCacheTimestamp resets expiry from current clock time', () {
      final baseTime = DateTime(2024, 1, 1, 12, 0, 0);
      var currentTime = baseTime;
      final cache = BggCache(games, 5, clock: () => currentTime);

      // Advance past expiry
      currentTime = baseTime.add(Duration(minutes: 10));
      expect(cache.isStale(), true);

      // Refresh resets the countdown from "now"
      cache.refreshCacheTimestamp();
      expect(cache.isStale(), false);

      // Still fresh 4 minutes after refresh
      currentTime = baseTime.add(Duration(minutes: 14));
      expect(cache.isStale(), false);

      // Stale 6 minutes after refresh
      currentTime = baseTime.add(Duration(minutes: 16));
      expect(cache.isStale(), true);
    });

    test('zero duration cache is immediately stale', () {
      final baseTime = DateTime(2024, 1, 1, 12, 0, 0);
      var currentTime = baseTime;
      final cache = BggCache(games, 0, clock: () => currentTime);

      // Even 1 second later it's stale
      currentTime = baseTime.add(Duration(seconds: 1));
      expect(cache.isStale(), true);
    });
  });
  group('makeStale', () {
    test('marks the cache as stale', () {
      var longDuration = 10;
      var cache = BggCache(games, longDuration);
      expect(cache.isStale(), false);
      cache.makeStale();
      expect(cache.isStale(), true);
    });
  });
  group('epochToSeconds', () {
    test('converts a millisecond epoch to seconds', () {
      var epoch = 1000;
      var expectedEpoch = 1;
      var cache = BggCache(games, duration);
      expect(cache.epochToSeconds(epoch), expectedEpoch);
    });
  });
  group('random', () {
    test('randomly provides a game from the collection', () {
      var cache = BggCache(games, duration);
      expect(cache.random, TypeMatcher<Game>());
    });
    test('returns a different game when called multiple times if available',
        () {
      var cache = BggCache(games, duration);
      var first = cache.random;
      var second = cache.random;
      expect(second != first, true);
    });
    test('returns the same random game when only one available', () {
      var cache = BggCache(Games(gamesByName: {game1.name: game1}), duration);
      var first = cache.random;
      var second = cache.random;
      expect(first, second);
    });
    test('returns null when no games available', () {
      var cache = BggCache(Games(), duration);
      expect(cache.random, null);
    });
  });
  group('lastRandom', () {
    test('selects a random game when called first', () {
      var cache = BggCache(games, duration);
      expect(cache.lastRandom, TypeMatcher<Game>());
    });
    test('returns a the same game once selected', () {
      var cache = BggCache(games, duration);
      var first = cache.lastRandom;
      expect(cache.lastRandom, first);
    });
  });
}
