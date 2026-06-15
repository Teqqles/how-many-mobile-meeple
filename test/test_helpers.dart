import 'package:how_many_mobile_meeple/model/game.dart';
import 'package:how_many_mobile_meeple/model/games.dart';

class TestHelpers {
  static Game game1() => Game(
        id: 1,
        name: 'Wingspan',
        maxPlayers: 5,
        minPlayers: 1,
        maxPlaytime: 70,
        imageUrl: 'http://example.com/wingspan.jpg',
        averageRating: 8.1,
        averageWeight: 2.4,
      );

  static Game game2() => Game(
        id: 2,
        name: 'Catan',
        maxPlayers: 4,
        minPlayers: 3,
        maxPlaytime: 120,
        imageUrl: 'http://example.com/catan.jpg',
        averageRating: 7.2,
        averageWeight: 2.3,
      );

  static Games twoGames() =>
      Games(gamesByName: {game1().name: game1(), game2().name: game2()});

  static Games oneGame() => Games(gamesByName: {game1().name: game1()});
}
