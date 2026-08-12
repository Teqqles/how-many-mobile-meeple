/// A lightweight snapshot of a game the user has viewed, captured at view time
/// so the recently-viewed list can render without any further API calls.
class RecentlyViewedGame {
  final int id;
  final String name;
  final String? thumbnail;

  RecentlyViewedGame({
    required this.id,
    required this.name,
    this.thumbnail,
  });

  factory RecentlyViewedGame.fromJson(Map<String, dynamic> json) {
    return RecentlyViewedGame(
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
