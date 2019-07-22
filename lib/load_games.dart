import 'dart:convert';
import 'package:http/http.dart' as http;

import 'game_config.dart';
import 'model.dart';

class LoadGames {
  static String permittedResponseFields =
      'name,maxplayers,minplayers,maxplaytime,image,thumbnail,stats';

  static Future<Games> fetchGames(Settings settings, List<Item> items) async {
    Games games = new Games(gamesByName: new Map<String, Game>());
    Map<String, String> requestHeaders = {
      'Bgg-Filter-Player-Count': settings.playerCount.toString(),
      'Bgg-Filter-Min-Duration': settings.minTime.toString(),
      'Bgg-Filter-Max-Duration': settings.maxTime.toString(),
      'Bgg-Field-Whitelist': permittedResponseFields
    };
    for (Item item in items) {
      var response = await http.get(
          "${GameConfig.boardGameGeekProxyUrl}/${item.itemType.name}/${item.name}",
          headers: requestHeaders);
      if (response.statusCode != 200) {
        throw Exception('Failed to load games for ${item.name}');
      } else {
        Games loadedGames = Games.fromJson(jsonDecode(response.body));
        games.addGames(loadedGames);
      }
    }

    return games;
  }
}

class Games {
  final Map<String, Game> gamesByName;

  List<Game> get games => gamesByName.values.toList();

  Games({this.gamesByName});

  factory Games.fromJson(List<dynamic> parsedJson) {
    var games = new Map<String, Game>();

    games = Map.fromEntries(parsedJson.map((gameData) {
      var gameFromJs = Game.fromJson(gameData);
      return MapEntry(gameFromJs.name, gameFromJs);
    }));

    return new Games(
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
}

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
