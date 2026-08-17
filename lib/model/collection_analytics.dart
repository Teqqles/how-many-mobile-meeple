class PlaytimeRange {
  final int min;
  final int? max;
  const PlaytimeRange(this.min, this.max);
}

class MechanicCount {
  final String name;
  final int count;
  const MechanicCount(this.name, this.count);
}

/// Headline figures for a collection. Every field is nullable so a partial
/// summary still parses; callers show only what is present.
class CollectionSummary {
  final int? totalGames;
  final int? baseGames;
  final int? expansions;
  final double? averageRating;
  final double? medianRating;
  final double? averageWeight;

  const CollectionSummary({
    this.totalGames,
    this.baseGames,
    this.expansions,
    this.averageRating,
    this.medianRating,
    this.averageWeight,
  });

  /// True when at least one figure is present.
  bool get hasData =>
      totalGames != null ||
      baseGames != null ||
      expansions != null ||
      averageRating != null ||
      medianRating != null ||
      averageWeight != null;
}

/// Per-player-count coverage: how many games [supported] that count, and how
/// many play [bestOrRecommended] at it.
class PlayerCountCoverage {
  final int playerCount;
  final int supported;
  final int bestOrRecommended;
  const PlayerCountCoverage(
    this.playerCount,
    this.supported,
    this.bestOrRecommended,
  );
}

/// A labelled bucket of a distribution (complexity or playtime) with the count
/// of games in it and the half-open numeric range `[min, max)` it covers.
/// A null [max] means the bucket is open-ended (e.g. `heavy [4.0+)`).
class DistributionBucket {
  final String name;
  final num min;
  final num? max;
  final int count;
  const DistributionBucket({
    required this.name,
    required this.min,
    this.max,
    required this.count,
  });

  /// True when [value] falls in the half-open range `[min, max)`.
  bool contains(num value) {
    final upper = max;
    return value >= min && (upper == null || value < upper);
  }

  /// True when the selected range `[lo, hi]` overlaps this bucket's `[min, max)`.
  bool overlaps(num lo, num hi) => lo < (max ?? double.infinity) && hi >= min;
}

class CollectionAnalytics {
  final int? mostCoveredPlayerCount;
  final double? averageWeight;
  final PlaytimeRange? dominantPlaytime;
  final List<MechanicCount> topMechanics;
  final List<PlayerCountCoverage> playerCountCoverage;
  final List<DistributionBucket> complexityDistribution;
  final List<DistributionBucket> playtimeDistribution;
  final CollectionSummary? summary;

  const CollectionAnalytics({
    this.mostCoveredPlayerCount,
    this.averageWeight,
    this.dominantPlaytime,
    this.topMechanics = const [],
    this.playerCountCoverage = const [],
    this.complexityDistribution = const [],
    this.playtimeDistribution = const [],
    this.summary,
  });

  /// True when any field parsed; false for an empty/not-ready response.
  bool get hasData =>
      summary != null ||
      mostCoveredPlayerCount != null ||
      averageWeight != null ||
      dominantPlaytime != null ||
      topMechanics.isNotEmpty ||
      playerCountCoverage.isNotEmpty ||
      complexityDistribution.isNotEmpty ||
      playtimeDistribution.isNotEmpty;

  factory CollectionAnalytics.fromJson(Map<String, dynamic> json) {
    return CollectionAnalytics(
      mostCoveredPlayerCount: _mostCoveredPlayerCount(
        json['player_count_coverage'],
      ),
      averageWeight: _averageWeight(json),
      dominantPlaytime: _dominantPlaytime(json['playtime_distribution']),
      topMechanics: _topMechanics(json['top_mechanics']),
      playerCountCoverage: _playerCountCoverage(json['player_count_coverage']),
      complexityDistribution: _floatBuckets(json['complexity_distribution']),
      playtimeDistribution: _intBuckets(json['playtime_distribution']),
      summary: _summary(json['summary']),
    );
  }

  /// Parses the `summary` block, or null when absent or carrying no usable
  /// figure (so a not-ready `{}` yields null, not an empty summary).
  static CollectionSummary? _summary(dynamic summary) {
    if (summary is! Map) return null;
    int? asInt(dynamic v) => v is int ? v : null;
    double? asDouble(dynamic v) => v is num ? v.toDouble() : null;
    final parsed = CollectionSummary(
      totalGames: asInt(summary['total_games']),
      baseGames: asInt(summary['base_games']),
      expansions: asInt(summary['expansions']),
      averageRating: asDouble(summary['average_rating']),
      medianRating: asDouble(summary['median_rating']),
      averageWeight: asDouble(summary['average_weight']),
    );
    return parsed.hasData ? parsed : null;
  }

  /// Parses `[{player_count, supported, best_or_recommended}, ...]` ascending
  /// by player count, dropping entries missing any field.
  static List<PlayerCountCoverage> _playerCountCoverage(dynamic list) {
    if (list is! List) return const [];
    final result = <PlayerCountCoverage>[];
    for (final entry in list) {
      if (entry is! Map) continue;
      final pc = entry['player_count'];
      final supported = entry['supported'];
      final best = entry['best_or_recommended'];
      if (pc is! int || supported is! int || best is! int) continue;
      result.add(PlayerCountCoverage(pc, supported, best));
    }
    result.sort((a, b) => a.playerCount.compareTo(b.playerCount));
    return result;
  }

  /// Parses a distribution list into buckets, dropping malformed entries.
  /// [parseRange] extracts the `[min, max)` numeric range from a label.
  static List<DistributionBucket> _buckets(
    dynamic dist,
    (num, num?)? Function(String) parseRange,
  ) {
    if (dist is! List) return const [];
    final result = <DistributionBucket>[];
    for (final entry in dist) {
      if (entry is! Map) continue;
      final label = entry['label'];
      final count = entry['count'];
      if (label is! String || count is! int) continue;
      final range = parseRange(label);
      if (range == null) continue;
      result.add(
        DistributionBucket(
          name: label.split('[').first.trim(),
          min: range.$1,
          max: range.$2,
          count: count,
        ),
      );
    }
    return result;
  }

  static List<DistributionBucket> _floatBuckets(dynamic dist) =>
      _buckets(dist, _parseFloatRange);

  static List<DistributionBucket> _intBuckets(dynamic dist) =>
      _buckets(dist, _parseIntRange);

  /// Parses `[{name, count}, ...]` into count-descending order, dropping
  /// malformed entries. Empty when the field is missing or not a list.
  static List<MechanicCount> _topMechanics(dynamic list) {
    if (list is! List) return const [];
    final result = <MechanicCount>[];
    for (final entry in list) {
      if (entry is! Map) continue;
      final name = entry['name'];
      final count = entry['count'];
      if (name is! String || count is! int) continue;
      result.add(MechanicCount(name, count));
    }
    result.sort((a, b) => b.count.compareTo(a.count));
    return result;
  }

  static int? _mostCoveredPlayerCount(dynamic coverage) {
    if (coverage is! List) return null;
    int? bestPc;
    int? bestScore;
    for (final entry in coverage) {
      if (entry is! Map) continue;
      final pc = entry['player_count'];
      final score = entry['best_or_recommended'];
      if (pc is! int || score is! int) continue;
      // Higher score wins; ties resolve to the lower player_count.
      if (bestScore == null ||
          score > bestScore ||
          (score == bestScore && pc < bestPc!)) {
        bestScore = score;
        bestPc = pc;
      }
    }
    return bestPc;
  }

  static double? _averageWeight(Map<String, dynamic> json) {
    final summary = json['summary'];
    if (summary is Map) {
      final w = summary['average_weight'];
      if (w is num) return w.toDouble();
    }
    // Fallback: midpoint of the highest-count complexity bucket.
    final dist = json['complexity_distribution'];
    final top = _highestCountLabel(dist);
    if (top == null) return null;
    final range = _parseFloatRange(top);
    if (range == null) return null;
    final lo = range.$1;
    final hi = range.$2;
    return hi == null ? lo : (lo + hi) / 2.0;
  }

  static PlaytimeRange? _dominantPlaytime(dynamic dist) {
    final label = _highestCountLabel(dist);
    if (label == null) return null;
    final range = _parseIntRange(label);
    if (range == null) return null;
    return PlaytimeRange(range.$1, range.$2);
  }

  /// Returns the `label` of the entry with the greatest `count`, or null.
  static String? _highestCountLabel(dynamic dist) {
    if (dist is! List) return null;
    String? bestLabel;
    int? bestCount;
    for (final entry in dist) {
      if (entry is! Map) continue;
      final count = entry['count'];
      final label = entry['label'];
      if (count is! int || label is! String) continue;
      if (bestCount == null || count > bestCount) {
        bestCount = count;
        bestLabel = label;
      }
    }
    return bestLabel;
  }

  /// Parses `"[lo, hi)"` -> (lo, hi); `"[lo+)"` -> (lo, null). Ints only.
  static (int, int?)? _parseIntRange(String label) {
    final closed = RegExp(r'\[(\d+),\s*(\d+)\)').firstMatch(label);
    if (closed != null) {
      final lo = int.tryParse(closed.group(1)!);
      final hi = int.tryParse(closed.group(2)!);
      if (lo == null || hi == null) return null;
      return (lo, hi);
    }
    final open = RegExp(r'\[(\d+)\+\)').firstMatch(label);
    if (open != null) {
      final lo = int.tryParse(open.group(1)!);
      if (lo == null) return null;
      return (lo, null);
    }
    return null;
  }

  /// As [_parseIntRange] but allows decimals (for complexity buckets).
  static (double, double?)? _parseFloatRange(String label) {
    final closed = RegExp(r'\[([\d.]+),\s*([\d.]+)\)').firstMatch(label);
    if (closed != null) {
      final lo = double.tryParse(closed.group(1)!);
      final hi = double.tryParse(closed.group(2)!);
      if (lo == null || hi == null) return null;
      return (lo, hi);
    }
    final open = RegExp(r'\[([\d.]+)\+\)').firstMatch(label);
    if (open != null) {
      final lo = double.tryParse(open.group(1)!);
      if (lo == null) return null;
      return (lo, null);
    }
    return null;
  }
}
