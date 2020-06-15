enum SortableGameField { name, maxPlaytime, rating, weight }

class Game {
  final int id;
  final String name;
  final int maxPlayers;
  final int minPlayers;
  final int maxPlaytime;
  final String imageUrl;
  final double averageRating;
  final double averageWeight;

  Game(
      {this.id,
      this.name,
      this.maxPlayers,
      this.minPlayers,
      this.maxPlaytime,
      this.imageUrl,
      this.averageRating,
      this.averageWeight});

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      id: json['id'],
      name: json['name'],
      maxPlayers: json['maxplayers'],
      minPlayers: json['minplayers'],
      maxPlaytime: json['maxplaytime'] ?? 0,
      imageUrl: json['image'],
      averageRating: json['stats']['average'] ?? 0,
      averageWeight: json['stats']['averageweight'] ?? 0,
    );
  }

  @override
  String toString() {
    return "$name ($id), $minPlayers, $maxPlayers";
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Game && toString() == other.toString();

  @override
  int get hashCode => toString().hashCode;
}
