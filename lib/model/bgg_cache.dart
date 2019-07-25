import 'dart:math';

import 'game.dart';
import 'games.dart';

class BggCache {
  Games _games;
  int _durationMinutes;
  int _cacheTimestamp;

  Games get games => _games;

  int get durationInMinutes => _durationMinutes;
  Game _stickyRandom;

  Game get random {
    var selectedGame = Random().nextInt(games.games.length);
    this._stickyRandom = games.games[selectedGame];
    return this._stickyRandom;
  }

  Game get lastRandom => _stickyRandom ?? random;

  BggCache(this._games, this._durationMinutes) {
    this._cacheTimestamp =
        epochToSeconds(DateTime.now().millisecondsSinceEpoch) +
            (this.durationInMinutes * 60);
  }

  int epochToSeconds(int millisEpoch) => (millisEpoch / 1000).floor();

  bool isStale() =>
      this._cacheTimestamp <
      epochToSeconds(DateTime.now().millisecondsSinceEpoch);

  void makeStale() => this._cacheTimestamp = 0;
}
