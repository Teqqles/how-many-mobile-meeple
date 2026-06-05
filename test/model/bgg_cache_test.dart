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
