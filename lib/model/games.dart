import 'game.dart';

class Games {
  final Map<String, Game> gamesByName;

  List<Game> get games => gamesByName.values.toList();

  Games({this.gamesByName: const {}});

  factory Games.fromJson(List<dynamic> parsedJson) {
    var games = Map<String, Game>();

    games = Map.fromEntries(parsedJson.map((gameData) {
      var gameFromJs = Game.fromJson(gameData);
      return MapEntry(gameFromJs.name, gameFromJs);
    }));

    return Games(
      gamesByName: games,
    );
  }

  Games addGames(Games newGames) {
    gamesByName.addAll(newGames.gamesByName);
    return this;
  }

  List<Game> getGamesByRating() {
    List<Game> unsortedGames = games;
    unsortedGames.sort((a, b) => b.averageRating.compareTo(a.averageRating));
    return unsortedGames;
  }

  Games clone() {
    return Games(gamesByName: gamesByName);
  }

  Games remove(Game game) {
    Map<String, Game> newGamesList = Map<String, Game>();
    newGamesList.addAll(gamesByName);
    newGamesList.remove(game.name);
    return Games(gamesByName: newGamesList);
  }

  @override
  String toString() {
    return gamesByName.toString();
  }
}
