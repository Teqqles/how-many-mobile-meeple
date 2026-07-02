enum SortableGameField { name, maxPlaytime, rating, weight, plays }

class Game {
  final int id;
  final String name;
  final int maxPlayers;
  final int minPlayers;
  final int maxPlaytime;
  final String imageUrl;
  final String? thumbnail;
  final double averageRating;
  final double averageWeight;

  /// The date this game entered the owner's collection. Null when the backend
  /// reported no date or a whitelist omitted the field.
  final DateTime? lastModified;

  Game({
    required this.id,
    required this.name,
    required this.maxPlayers,
    required this.minPlayers,
    required this.maxPlaytime,
    required this.imageUrl,
    this.thumbnail,
    required this.averageRating,
    required this.averageWeight,
    this.lastModified,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      id: json['id'],
      name: json['name'],
      maxPlayers: json['maxplayers'] ?? 0,
      minPlayers: json['minplayers'] ?? 0,
      maxPlaytime: json['maxplaytime'] ?? 0,
      imageUrl: json['image'] ?? '',
      thumbnail: json['thumbnail'],
      averageRating: (json['stats']['average'] ?? 0).toDouble(),
      averageWeight: (json['stats']['averageweight'] ?? 0).toDouble(),
      lastModified: _parseLastModified(json['lastmodified']),
    );
  }

  static DateTime? _parseLastModified(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
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
