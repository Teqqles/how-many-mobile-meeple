import 'package:how_many_mobile_meeple/model/game.dart';

class Recommendation {
  final int gameId;
  final String name;
  final double similarityScore;
  final Game? game;

  Recommendation({
    required this.gameId,
    required this.name,
    required this.similarityScore,
    this.game,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      gameId: json['game_id'],
      name: json['name'],
      similarityScore: (json['similarity_score'] as num).toDouble(),
      game: json['game'] != null
          ? Game.fromJson(json['game'] as Map<String, dynamic>)
          : null,
    );
  }
}
