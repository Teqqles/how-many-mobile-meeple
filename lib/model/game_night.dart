import 'dart:math';

import 'package:how_many_mobile_meeple/model/game.dart';

/// The three slots that make up an evening's lineup. The optional expansion
/// slot from the design is deferred until the backend exposes expansion
/// relationships (see issue #119).
enum GameNightSlot { filler, main, backup }

/// A recommended evening lineup. Any slot may be null when the collection
/// cannot fill it within the time budget.
class GameNightLineup {
  final Game? filler;
  final Game? main;
  final Game? backup;

  const GameNightLineup({this.filler, this.main, this.backup});

  Game? slot(GameNightSlot slot) => switch (slot) {
    GameNightSlot.filler => filler,
    GameNightSlot.main => main,
    GameNightSlot.backup => backup,
  };

  bool get isEmpty => filler == null && main == null && backup == null;
}

/// Builds a Game Night lineup from a pool of games and a time budget.
///
/// Pure and dependency-free: selection among equally valid candidates goes
/// through [_pick], which tests override for deterministic results.
class GameNightPlanner {
  /// A filler is a short game played while waiting or warming up.
  static const int fillerMaxMinutes = 20;

  final int Function(int count) _pick;

  GameNightPlanner({int Function(int count)? pick})
    : _pick = pick ?? ((count) => Random().nextInt(count));

  /// Fills the unpinned slots from [pool] within [durationMinutes].
  ///
  /// Pinned games are kept in their slot and never reused elsewhere. The
  /// filler plus the main game must fit the budget; the backup is an
  /// alternative to the main, so it does not add to the total playtime.
  GameNightLineup plan({
    required List<Game> pool,
    required int durationMinutes,
    Map<GameNightSlot, Game> pinned = const {},
  }) {
    final used = pinned.values.map((g) => g.id).toSet();

    final filler = pinned[GameNightSlot.filler] ?? _pickFiller(pool, used);
    if (filler != null) used.add(filler.id);

    final remaining = durationMinutes - (filler?.maxPlaytime ?? 0);
    final main = pinned[GameNightSlot.main] ?? _pickMain(pool, used, remaining);
    if (main != null) used.add(main.id);

    final backup =
        pinned[GameNightSlot.backup] ?? _pickBackup(pool, used, main);

    return GameNightLineup(filler: filler, main: main, backup: backup);
  }

  Game? _pickFiller(List<Game> pool, Set<int> used) {
    final candidates = pool
        .where(
          (g) =>
              !used.contains(g.id) &&
              g.maxPlaytime > 0 &&
              g.maxPlaytime < fillerMaxMinutes,
        )
        .toList();
    return _choose(candidates);
  }

  Game? _pickMain(List<Game> pool, Set<int> used, int remaining) {
    final fitting = pool
        .where(
          (g) =>
              !used.contains(g.id) &&
              g.maxPlaytime > 0 &&
              g.maxPlaytime <= remaining,
        )
        .toList();
    if (fitting.isEmpty) return null;

    // The centrepiece is the longest game that still fits the budget.
    final longest = fitting
        .map((g) => g.maxPlaytime)
        .reduce((a, b) => a > b ? a : b);
    final centrepieces = fitting
        .where((g) => g.maxPlaytime == longest)
        .toList();
    return _choose(centrepieces);
  }

  Game? _pickBackup(List<Game> pool, Set<int> used, Game? main) {
    if (main == null) return null;

    final tolerance = max(15, (main.maxPlaytime * 0.3).round());
    final similar = pool
        .where(
          (g) =>
              !used.contains(g.id) &&
              g.maxPlaytime > 0 &&
              (g.maxPlaytime - main.maxPlaytime).abs() <= tolerance,
        )
        .toList();
    if (similar.isEmpty) return null;

    // Prefer a backup in a different complexity band so it feels like a real
    // alternative; fall back to any similarly timed game.
    final mainBand = _weightBand(main.averageWeight);
    final contrasting = similar
        .where((g) => _weightBand(g.averageWeight) != mainBand)
        .toList();
    return _choose(contrasting.isNotEmpty ? contrasting : similar);
  }

  Game? _choose(List<Game> candidates) {
    if (candidates.isEmpty) return null;
    return candidates[_pick(candidates.length)];
  }

  static int _weightBand(double weight) {
    if (weight < 2.0) return 0;
    if (weight <= 3.0) return 1;
    return 2;
  }
}
