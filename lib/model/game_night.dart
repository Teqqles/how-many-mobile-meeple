import 'dart:math';

import 'package:how_many_mobile_meeple/model/game.dart';

/// The slots that make up an evening's lineup. The outro is a wind-down game
/// played after the main on a long night; the optional expansion slot from the
/// design is deferred until the backend exposes expansion relationships (see
/// issue #119).
enum GameNightSlot { filler, main, backup, outro }

/// A recommended evening lineup. Any slot may be null when the collection
/// cannot fill it within the time budget.
class GameNightLineup {
  final Game? filler;
  final Game? main;
  final Game? backup;
  final Game? outro;

  const GameNightLineup({this.filler, this.main, this.backup, this.outro});

  Game? slot(GameNightSlot slot) => switch (slot) {
    GameNightSlot.filler => filler,
    GameNightSlot.main => main,
    GameNightSlot.backup => backup,
    GameNightSlot.outro => outro,
  };

  bool get isEmpty =>
      filler == null && main == null && backup == null && outro == null;
}

/// Serialises a lineup's game ids for a shareable permalink and reads them
/// back. The token is four `-`-separated ids in slot order, with `0` marking
/// an empty slot, e.g. `12-45-0-8` (filler 12, main 45, no backup, outro 8).
class GameNightPermalink {
  static const String _separator = '-';

  static String encode(GameNightLineup lineup) => [
    lineup.filler?.id ?? 0,
    lineup.main?.id ?? 0,
    lineup.backup?.id ?? 0,
    lineup.outro?.id ?? 0,
  ].join(_separator);

  /// Maps each slot to the game id carried in [token], skipping empty slots.
  /// A malformed token yields an empty map so the lineup regenerates normally.
  static Map<GameNightSlot, int> decode(String token) {
    final ids = token.split(_separator).map(int.tryParse).toList();
    if (ids.length != 4) return const {};

    final bySlot = {
      GameNightSlot.filler: ids[0],
      GameNightSlot.main: ids[1],
      GameNightSlot.backup: ids[2],
      GameNightSlot.outro: ids[3],
    };
    bySlot.removeWhere((_, id) => id == null || id <= 0);
    return bySlot.map((slot, id) => MapEntry(slot, id!));
  }
}

/// Builds a Game Night lineup from a pool of games and a time budget.
///
/// Pure and dependency-free: selection among equally valid candidates goes
/// through [_pick], which tests override for deterministic results.
class GameNightPlanner {
  /// A filler is a short game played while waiting or warming up. The ceiling
  /// is inclusive so common 30-minute fillers qualify.
  static const int fillerMaxMinutes = 30;

  /// The main can be any fitting game whose playtime is at least this fraction
  /// of the longest fitting game, so regenerate varies the centrepiece instead
  /// of always returning the single longest title.
  static const double mainLengthTolerance = 0.7;

  /// The outro is a wind-down closer, only worth suggesting once the evening is
  /// long enough that the filler and main will not fill it. Offered only above
  /// this budget, and only when a short game still fits the leftover time.
  static const int outroMinDurationMinutes = 120;

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
    Map<GameNightSlot, String> slotMechanics = const {},
    bool includeOutro = true,
  }) {
    final used = pinned.values.map((g) => g.id).toSet();

    final filler =
        pinned[GameNightSlot.filler] ??
        _pickFiller(pool, used, slotMechanics[GameNightSlot.filler]);
    if (filler != null) used.add(filler.id);

    final remaining = durationMinutes - (filler?.maxPlaytime ?? 0);
    final main =
        pinned[GameNightSlot.main] ??
        _pickMain(pool, used, remaining, slotMechanics[GameNightSlot.main]);
    if (main != null) used.add(main.id);

    final backup =
        pinned[GameNightSlot.backup] ??
        _pickBackup(pool, used, main, slotMechanics[GameNightSlot.backup]);

    // The backup is an alternative to the main, so it is not "used" against the
    // outro - either the main or the backup is played, never both.
    final outro = !includeOutro
        ? null
        : pinned[GameNightSlot.outro] ??
              _pickOutro(
                pool,
                used,
                durationMinutes,
                filler,
                main,
                slotMechanics[GameNightSlot.outro],
              );

    return GameNightLineup(
      filler: filler,
      main: main,
      backup: backup,
      outro: outro,
    );
  }

  /// A slot's mechanic quick-pick narrows its candidates to games carrying that
  /// mechanic; null means the slot draws from the whole pool.
  bool _matchesMechanic(Game game, String? mechanic) =>
      mechanic == null || game.mechanics.contains(mechanic);

  Game? _pickFiller(List<Game> pool, Set<int> used, String? mechanic) {
    final candidates = pool
        .where(
          (g) =>
              !used.contains(g.id) &&
              g.maxPlaytime > 0 &&
              g.maxPlaytime <= fillerMaxMinutes &&
              _matchesMechanic(g, mechanic),
        )
        .toList();
    return _choose(candidates);
  }

  Game? _pickMain(
    List<Game> pool,
    Set<int> used,
    int remaining,
    String? mechanic,
  ) {
    final fitting = pool
        .where(
          (g) =>
              !used.contains(g.id) &&
              g.maxPlaytime > 0 &&
              g.maxPlaytime <= remaining &&
              _matchesMechanic(g, mechanic),
        )
        .toList();
    if (fitting.isEmpty) return null;

    // The centrepiece is a long game, but not rigidly the single longest -
    // any game within a band below the longest is a fair candidate so
    // regenerate can offer variety instead of always the same top game.
    final longest = fitting
        .map((g) => g.maxPlaytime)
        .reduce((a, b) => a > b ? a : b);
    final threshold = longest * mainLengthTolerance;
    final centrepieces = fitting
        .where((g) => g.maxPlaytime >= threshold)
        .toList();
    return _choose(centrepieces);
  }

  Game? _pickBackup(
    List<Game> pool,
    Set<int> used,
    Game? main,
    String? mechanic,
  ) {
    if (main == null) return null;

    final tolerance = max(15, (main.maxPlaytime * 0.3).round());
    final similar = pool
        .where(
          (g) =>
              !used.contains(g.id) &&
              g.maxPlaytime > 0 &&
              (g.maxPlaytime - main.maxPlaytime).abs() <= tolerance &&
              _matchesMechanic(g, mechanic),
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

  Game? _pickOutro(
    List<Game> pool,
    Set<int> used,
    int durationMinutes,
    Game? filler,
    Game? main,
    String? mechanic,
  ) {
    // A closer only makes sense on a long night, once the main is set and time
    // is left over to play it in.
    if (durationMinutes <= outroMinDurationMinutes || main == null) return null;
    final remaining =
        durationMinutes - (filler?.maxPlaytime ?? 0) - main.maxPlaytime;

    final candidates = pool
        .where(
          (g) =>
              !used.contains(g.id) &&
              g.maxPlaytime > 0 &&
              g.maxPlaytime <= fillerMaxMinutes &&
              g.maxPlaytime <= remaining &&
              _matchesMechanic(g, mechanic),
        )
        .toList();
    return _choose(candidates);
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
