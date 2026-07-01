/// One participant in a BGG-recorded play.
class BggPlayer {
  final String name;

  /// The participant's BGG account name, if they have one. Retained so the
  /// account holder can be matched to their real [name] when pre-filling plays.
  final String username;
  final int? score;
  final bool win;

  BggPlayer({
    required this.name,
    this.username = '',
    this.score,
    this.win = false,
  });

  factory BggPlayer.fromJson(Map<String, dynamic> json) {
    // Prefer the real name, fall back to the BGG username.
    final name = (json['name'] as String?)?.trim();
    final username = (json['username'] as String?)?.trim() ?? '';
    final score = json['score'];
    return BggPlayer(
      name: (name != null && name.isNotEmpty) ? name : username,
      username: username,
      score:
          score is num ? score.round() : int.tryParse(score?.toString() ?? ''),
      win: json['win'] == true,
    );
  }
}

/// A single dated play recorded on BGG.
class BggPlay {
  final int playId;
  final DateTime? date;
  final int length;
  final List<BggPlayer> players;

  BggPlay({
    required this.playId,
    this.date,
    this.length = 0,
    this.players = const [],
  });

  factory BggPlay.fromJson(Map<String, dynamic> json) => BggPlay(
        playId: json['play_id'] as int,
        date: _parseDate(json['date']),
        length: json['length'] ?? 0,
        players: (json['players'] as List?)
                ?.map((e) => BggPlayer.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  static DateTime? _parseDate(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}

/// A BGG play paired with the game it belongs to, for chronological display.
class BggPlayRecord {
  final int gameId;
  final String gameName;
  final String? thumbnail;
  final BggPlay play;

  BggPlayRecord({
    required this.gameId,
    required this.gameName,
    this.thumbnail,
    required this.play,
  });
}

class PlayData {
  final int gameId;
  final String gameName;
  final int totalPlays;
  final List<BggPlay> plays;

  PlayData({
    required this.gameId,
    required this.gameName,
    required this.totalPlays,
    this.plays = const [],
  });

  factory PlayData.fromJson(Map<String, dynamic> json) => PlayData(
        gameId: json['game_id'],
        gameName: json['game_name'],
        totalPlays: json['total_plays'] ?? 0,
        plays: (json['plays'] as List?)
                ?.map((e) => BggPlay.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayData &&
          runtimeType == other.runtimeType &&
          gameId == other.gameId;

  @override
  int get hashCode => gameId.hashCode;

  @override
  String toString() => '$gameName (id: $gameId, plays: $totalPlays)';
}
