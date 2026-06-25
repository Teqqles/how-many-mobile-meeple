class FavouriteGame {
  final int id;
  final String name;
  final String? thumbnail;

  FavouriteGame({
    required this.id,
    required this.name,
    this.thumbnail,
  });

  factory FavouriteGame.fromJson(Map<String, dynamic> json) {
    return FavouriteGame(
      id: json['id'],
      name: json['name'],
      thumbnail: json['thumbnail'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'thumbnail': thumbnail,
      };
}
