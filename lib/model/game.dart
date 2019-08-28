class Game {
  final String name;
  final int maxPlayers;
  final int minPlayers;
  final int maxPlaytime;
  final String imageUrl;
  final double averageRating;
  final double averageWeight;

  Game(
      {this.name,
      this.maxPlayers,
      this.minPlayers,
      this.maxPlaytime,
      this.imageUrl,
      this.averageRating,
      this.averageWeight});

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      name: json['name'],
      maxPlayers: json['maxplayers'],
      minPlayers: json['minplayers'],
      maxPlaytime: json['maxplaytime'],
      imageUrl: json['image'],
      averageRating: json['stats']['average'] ?? 0,
      averageWeight: json['stats']['averageweight'] ?? 0,
    );
  }

  @override
  String toString() {
    return "$name, $minPlayers, $maxPlayers";
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Game && toString() == other.toString();

  @override
  int get hashCode => toString().hashCode;
}
