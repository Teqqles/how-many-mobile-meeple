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
  /// Playtime ceiling for a filler or the wind-down outro. Inclusive.
  static const int fillerMaxMinutes = 45;

  /// The main must be at least this fraction of the longest fitting game, so
  /// regenerate varies the centrepiece instead of always the longest title.
  static const double mainLengthTolerance = 0.7;

  /// Suggest an outro only past this budget, and only when a short game still
  /// fits the leftover time.
  static const int outroMinDurationMinutes = 120;

  /// Draw entries per favourite: this many times likelier than an equal
  /// non-favourite - a nudge, not a guarantee.
  static const int favouriteWeight = 3;

  /// Setup/teardown minutes reserved around a game, by weight, charged against
  /// the budget alongside its playtime.
  static const int lightOverheadMinutes = 5;
  static const int mediumOverheadMinutes = 10;
  static const int heavyOverheadMinutes = 15;

  final int Function(int count) _pick;

  /// Favourite ids, weighted up in every draw for one [plan] call.
  Set<int> _favourites = const {};

  /// Play counts by game id; break the empty-slot fallback toward well-played
  /// games. Empty until plays load, when the fallback falls back on length.
  Map<int, int> _playCounts = const {};

  GameNightPlanner({int Function(int count)? pick})
    : _pick = pick ?? ((count) => Random().nextInt(count));

  /// Fills the unpinned slots from [pool] within [durationMinutes]. Pinned
  /// games stay put and are never reused. Filler plus main must fit the
  /// budget; the backup is an alternative to the main, so it adds no time.
  GameNightLineup plan({
    required List<Game> pool,
    required int durationMinutes,
    Map<GameNightSlot, Game> pinned = const {},
    Map<GameNightSlot, String> slotMechanics = const {},
    bool includeOutro = true,
    Set<int> favouriteIds = const {},
    Map<int, int> playCounts = const {},
  }) {
    _favourites = favouriteIds;
    _playCounts = playCounts;
    final used = pinned.values.map((g) => g.id).toSet();

    final filler =
        pinned[GameNightSlot.filler] ??
        _pickFiller(pool, used, slotMechanics[GameNightSlot.filler]);
    if (filler != null) used.add(filler.id);

    final remaining = durationMinutes - _cost(filler);
    final main =
        pinned[GameNightSlot.main] ??
        _pickMain(pool, used, remaining, slotMechanics[GameNightSlot.main]);
    if (main != null) used.add(main.id);

    final backup =
        pinned[GameNightSlot.backup] ??
        _pickBackup(
          pool,
          used,
          main,
          remaining,
          slotMechanics[GameNightSlot.backup],
        );

    // Backup is an alternative to the main, so it is not used against the outro.
    final outro = !includeOutro
        ? null
        : pinned[GameNightSlot.outro] ??
              _pickOutro(
                pool,
                used,
                durationMinutes,
                remaining,
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

  /// Narrows candidates to games carrying [mechanic]; null draws from the pool.
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
              _cost(g) <= remaining &&
              _matchesMechanic(g, mechanic),
        )
        .toList();
    if (fitting.isEmpty) return null;

    // A long game, but not rigidly the longest - anything within a band of the
    // longest counts, so regenerate can vary the centrepiece.
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
    int remaining,
    String? mechanic,
  ) {
    if (main == null) return null;

    final tolerance = max(15, (main.maxPlaytime * 0.3).round());
    final similar = pool
        .where(
          (g) =>
              !used.contains(g.id) &&
              g.maxPlaytime > 0 &&
              _cost(g) <= remaining &&
              (g.maxPlaytime - main.maxPlaytime).abs() <= tolerance &&
              _matchesMechanic(g, mechanic),
        )
        .toList();
    if (similar.isEmpty) return null;

    // Prefer a different complexity band so the backup feels like a real
    // alternative; else any similar-length game.
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
    int remainingAfterFiller,
    Game? main,
    String? mechanic,
  ) {
    // A closer needs a long night, a set main, and leftover time to play it.
    if (durationMinutes <= outroMinDurationMinutes || main == null) return null;
    final remaining = remainingAfterFiller - _cost(main);

    final candidates = pool
        .where(
          (g) =>
              !used.contains(g.id) &&
              g.maxPlaytime > 0 &&
              g.maxPlaytime <= fillerMaxMinutes &&
              _cost(g) <= remaining &&
              _matchesMechanic(g, mechanic),
        )
        .toList();
    final closer = _choose(candidates);
    if (closer != null) return closer;

    // No short closer fits: offer a well-played game that still fits - fast to
    // set up for a few quick rounds.
    final fallback = pool
        .where(
          (g) =>
              !used.contains(g.id) &&
              g.maxPlaytime > 0 &&
              _cost(g) <= remaining &&
              _matchesMechanic(g, mechanic),
        )
        .toList();
    return _pickReplayable(fallback);
  }

  /// Most-played game in [candidates]; with no play history the shortest wins,
  /// as it is the easiest to replay. Null when empty.
  Game? _pickReplayable(List<Game> candidates) {
    if (candidates.isEmpty) return null;

    final played =
        candidates.where((g) => (_playCounts[g.id] ?? 0) > 0).toList()
          ..sort((a, b) => _playCounts[b.id]!.compareTo(_playCounts[a.id]!));
    if (played.isNotEmpty) return played.first;

    return ([
      ...candidates,
    ]..sort((a, b) => a.maxPlaytime.compareTo(b.maxPlaytime))).first;
  }

  Game? _choose(List<Game> candidates) {
    if (candidates.isEmpty) return null;
    final weighted = _weightFavourites(candidates);
    return weighted[_pick(weighted.length)];
  }

  /// Repeats each favourite in the draw list to boost it without excluding
  /// others. Order is kept, so [_pick] 0 still lands on the first candidate.
  List<Game> _weightFavourites(List<Game> candidates) {
    if (_favourites.isEmpty) return candidates;
    final weighted = <Game>[];
    for (final game in candidates) {
      final copies = _favourites.contains(game.id) ? favouriteWeight : 1;
      for (var i = 0; i < copies; i++) {
        weighted.add(game);
      }
    }
    return weighted;
  }

  /// Playtime plus reserved overhead. An unfilled slot costs nothing.
  int _cost(Game? game) =>
      game == null ? 0 : game.maxPlaytime + overheadFor(game);

  /// Setup/teardown minutes for [game] by weight; the view shows this as the
  /// changeover between sections.
  static int overheadFor(Game game) =>
      switch (_weightBand(game.averageWeight)) {
        0 => lightOverheadMinutes,
        1 => mediumOverheadMinutes,
        _ => heavyOverheadMinutes,
      };

  /// Budget minus every played game and its overhead, clamped at zero. The
  /// backup is an alternative to the main, so it never counts.
  static int spareMinutes({
    required int durationMinutes,
    Game? filler,
    Game? main,
    Game? outro,
  }) {
    var used = 0;
    for (final game in [filler, main, outro]) {
      if (game != null) used += game.maxPlaytime + overheadFor(game);
    }
    final spare = durationMinutes - used;
    return spare < 0 ? 0 : spare;
  }

  static int _weightBand(double weight) {
    if (weight < 2.0) return 0;
    if (weight <= 3.0) return 1;
    return 2;
  }
}
