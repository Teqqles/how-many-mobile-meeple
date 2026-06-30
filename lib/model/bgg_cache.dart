import 'dart:math';

import 'package:how_many_mobile_meeple/favourites/favourites_service.dart';
import 'package:how_many_mobile_meeple/favourites/ignored_games_service.dart';

import 'game.dart';
import 'games.dart';

typedef ClockFunction = DateTime Function();

class BggCache {
  Games _games;
  int _durationMinutes;
  late int _cacheTimestamp;
  final ClockFunction _clock;

  Games get games => _games;
  late List<Game> _remainingPool;

  int get durationInMinutes => _durationMinutes;
  Game? _stickyRandom;

  static const int _favouriteWeight = 3;

  Game? get random {
    if (games.games.isEmpty) {
      return null;
    }
    _removeIgnoredFromPool();
    if (_remainingPool.isEmpty) {
      return _validatedSticky;
    }
    _stickyRandom = _nextRandom();
    return _stickyRandom;
  }

  Game _nextRandom() {
    var randomIndex = Random().nextInt(_remainingPool.length);
    var selectedGame = _remainingPool[randomIndex];
    _remainingPool.removeWhere((g) => g.id == selectedGame.id);
    return selectedGame;
  }

  void _removeIgnoredFromPool() {
    final ignoredService = IgnoredGamesService.cached;
    if (ignoredService == null) return;
    _remainingPool.removeWhere((g) => ignoredService.contains(g.id));
  }

  Game? get _validatedSticky {
    if (_stickyRandom == null) return null;
    final ignoredService = IgnoredGamesService.cached;
    if (ignoredService != null && ignoredService.contains(_stickyRandom!.id)) {
      _stickyRandom = null;
    }
    return _stickyRandom;
  }

  Game? get lastRandom => _validatedSticky ?? random;

  BggCache(this._games, this._durationMinutes, {ClockFunction? clock})
      : _clock = clock ?? DateTime.now {
    refreshCacheTimestamp();
    _remainingPool = _buildWeightedPool();
  }

  Game? randomIncludingIgnored() {
    final pool = _buildWeightedPool(includeIgnored: true);
    if (pool.isEmpty) return null;
    final index = Random().nextInt(pool.length);
    return pool[index];
  }

  List<Game> _buildWeightedPool({bool includeIgnored = false}) {
    final ignoredService = IgnoredGamesService.cached;
    final favouritesService = FavouritesService.cached;

    var pool = _games.games;
    if (!includeIgnored) {
      pool = pool
          .where((g) => !(ignoredService?.contains(g.id) ?? false))
          .toList();
    }

    if (favouritesService != null) {
      final extras = <Game>[];
      for (final game in pool) {
        if (favouritesService.contains(game.id)) {
          for (var i = 1; i < _favouriteWeight; i++) {
            extras.add(game);
          }
        }
      }
      pool = [...pool, ...extras];
    }

    pool.shuffle();
    return pool;
  }

  int epochToSeconds(int millisEpoch) => (millisEpoch / 1000).floor();

  bool isStale() =>
      this._cacheTimestamp < epochToSeconds(_clock().millisecondsSinceEpoch);

  void makeStale() => this._cacheTimestamp = 0;

  void refreshCacheTimestamp() {
    this._cacheTimestamp = epochToSeconds(_clock().millisecondsSinceEpoch) +
        (this.durationInMinutes * 60);
  }
}
