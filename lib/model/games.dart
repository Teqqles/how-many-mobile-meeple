import 'game.dart';

enum SortOrder { Asc, Desc }

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

  List<Game> getGamesBy(
      {SortableGameField field = SortableGameField.rating,
      SortOrder order = SortOrder.Desc}) {
    switch (field) {
      case SortableGameField.name:
        return getGamesByName(order);
        break;
      case SortableGameField.weight:
        return getGamesByWeight(order);
      default:
        return getGamesByRating(order);
    }
  }

  List<Game> getGamesByRating(SortOrder order) {
    List<Game> unsortedGames = games;

    switch (order) {
      case SortOrder.Asc:
        unsortedGames
            .sort((a, b) => a.averageRating.compareTo(b.averageRating));
        break;
      case SortOrder.Desc:
        unsortedGames
            .sort((a, b) => b.averageRating.compareTo(a.averageRating));
        break;
    }
    return unsortedGames;
  }

  List<Game> getGamesByName(SortOrder order) {
    List<Game> unsortedGames = games;

    switch (order) {
      case SortOrder.Asc:
        unsortedGames.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SortOrder.Desc:
        unsortedGames.sort((a, b) => b.name.compareTo(a.name));
        break;
    }
    return unsortedGames;
  }

  List<Game> getGamesByWeight(SortOrder order) {
    List<Game> unsortedGames = games;

    switch (order) {
      case SortOrder.Asc:
        unsortedGames
            .sort((a, b) => a.averageWeight.compareTo(b.averageWeight));
        break;
      case SortOrder.Desc:
        unsortedGames
            .sort((a, b) => b.averageWeight.compareTo(a.averageWeight));
        break;
    }
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
