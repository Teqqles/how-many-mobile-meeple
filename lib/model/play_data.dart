class PlayData {
  final int gameId;
  final String gameName;
  final int totalPlays;

  PlayData({
    required this.gameId,
    required this.gameName,
    required this.totalPlays,
  });

  factory PlayData.fromJson(Map<String, dynamic> json) => PlayData(
        gameId: json['game_id'],
        gameName: json['game_name'],
        totalPlays: json['total_plays'] ?? 0,
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
