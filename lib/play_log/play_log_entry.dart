/// A single recorded result for one player within a logged play.
///
/// All fields beyond [name] are optional: a play might record only who was
/// there, or additionally who won and their score.
class PlayerResult {
  final String name;
  final bool won;
  final int? score;

  PlayerResult({
    required this.name,
    this.won = false,
    this.score,
  });

  PlayerResult copyWith({String? name, bool? won, int? score}) => PlayerResult(
        name: name ?? this.name,
        won: won ?? this.won,
        score: score ?? this.score,
      );

  // Stored with short keys to keep the persisted log compact: n=name, w=won,
  // s=score. Defaults (won=false, no score) are omitted entirely.
  factory PlayerResult.fromJson(Map<String, dynamic> json) => PlayerResult(
        name: (json['n'] ?? json['name']) as String,
        won: json['w'] == 1 || json['w'] == true || json['won'] == true,
        score: json['s'] ?? json['score'],
      );

  Map<String, dynamic> toJson() => {
        'n': name,
        if (won) 'w': 1,
        if (score != null) 's': score,
      };
}

/// A logged play of a game at a point in time.
///
/// A game can be logged many times, so [id] uniquely identifies the entry
/// while [gameId] links it back to the game. [players] is optional and holds
/// who took part along with any winner/score details.
class PlayLogEntry {
  final String id;
  final int gameId;
  final String name;
  final String? thumbnail;
  final DateTime playedAt;
  final List<PlayerResult> players;

  PlayLogEntry({
    required this.id,
    required this.gameId,
    required this.name,
    this.thumbnail,
    required this.playedAt,
    this.players = const [],
  });

  // Stored compactly: i=id, g=gameId, n=name, t=thumbnail, d=playedAt as epoch
  // millis (shorter than ISO strings), p=players. Optional/empty fields are
  // omitted. Legacy long-key entries are still read for backward compatibility.
  factory PlayLogEntry.fromJson(Map<String, dynamic> json) => PlayLogEntry(
        id: (json['i'] ?? json['id']) as String,
        gameId: (json['g'] ?? json['gameId']) as int,
        name: (json['n'] ?? json['name']) as String,
        thumbnail: (json['t'] ?? json['thumbnail']) as String?,
        playedAt: _parseDate(json['d'] ?? json['playedAt']),
        players: ((json['p'] ?? json['players']) as List?)
                ?.map((e) => PlayerResult.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  Map<String, dynamic> toJson() => {
        'i': id,
        'g': gameId,
        'n': name,
        if (thumbnail != null) 't': thumbnail,
        'd': playedAt.millisecondsSinceEpoch,
        if (players.isNotEmpty) 'p': players.map((p) => p.toJson()).toList(),
      };

  static DateTime _parseDate(Object? value) {
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return DateTime.parse(value as String);
  }
}
