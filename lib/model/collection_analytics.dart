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

class CollectionAnalytics {
  final int? mostCoveredPlayerCount;
  final double? averageWeight;
  final PlaytimeRange? dominantPlaytime;
  final List<MechanicCount> topMechanics;

  const CollectionAnalytics({
    this.mostCoveredPlayerCount,
    this.averageWeight,
    this.dominantPlaytime,
    this.topMechanics = const [],
  });

  /// True when any field parsed; false for an empty/not-ready response.
  bool get hasData =>
      mostCoveredPlayerCount != null ||
      averageWeight != null ||
      dominantPlaytime != null ||
      topMechanics.isNotEmpty;

  factory CollectionAnalytics.fromJson(Map<String, dynamic> json) {
    return CollectionAnalytics(
      mostCoveredPlayerCount:
          _mostCoveredPlayerCount(json['player_count_coverage']),
      averageWeight: _averageWeight(json),
      dominantPlaytime: _dominantPlaytime(json['playtime_distribution']),
      topMechanics: _topMechanics(json['top_mechanics']),
    );
  }

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
