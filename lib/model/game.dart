class Game {
  final String name;
  final int maxPlayers;
  final int minPlayers;
  final int maxPlaytime;
  final String imageUrl;
  final String thumbnailUrl;
  final double averageRating;

  Game(
      {this.name,
        this.maxPlayers,
        this.minPlayers,
        this.maxPlaytime,
        this.imageUrl,
        this.thumbnailUrl,
        this.averageRating});

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      name: json['name'],
      maxPlayers: json['maxplayers'],
      minPlayers: json['minplayers'],
      maxPlaytime: json['maxplaytime'],
      imageUrl: json['image'],
      thumbnailUrl: json['thumbnail'],
      averageRating: json['stats']['average'] ?? 0,
    );
  }
}