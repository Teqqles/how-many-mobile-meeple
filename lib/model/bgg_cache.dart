import 'dart:math';

import 'game.dart';
import 'games.dart';

class BggCache {
  Games _games;
  int _durationMinutes;
  int _cacheTimestamp;

  Games get games => _games;
  Games _remainingGames;

  int get durationInMinutes => _durationMinutes;
  Game _stickyRandom;

  Game get random {
    if (games.games.isEmpty) {
      return null;
    }
    if (_remainingGames.games.isEmpty && _stickyRandom != null) {
      return _stickyRandom;
    }
    _stickyRandom = _nextRandom();
    return _stickyRandom;
  }

  Game _nextRandom() {
    var randomGameId = Random().nextInt(_remainingGames.games.length);
    var selectedGame = _remainingGames.games[randomGameId];
    _cacheRemaining(selectedGame);
    return selectedGame;
  }

  void _cacheRemaining(Game game) {
    _remainingGames = _games.remove(game);
  }

  Game get lastRandom => _stickyRandom ?? random;

  BggCache(this._games, this._durationMinutes) {
    refreshCacheTimestamp();
    _remainingGames = _games;
  }

  int epochToSeconds(int millisEpoch) => (millisEpoch / 1000).floor();

  bool isStale() =>
      this._cacheTimestamp <
      epochToSeconds(DateTime.now().millisecondsSinceEpoch);

  void makeStale() => this._cacheTimestamp = 0;

  void refreshCacheTimestamp() {
    this._cacheTimestamp =
        epochToSeconds(DateTime.now().millisecondsSinceEpoch) +
            (this.durationInMinutes * 60);
  }
}
