import 'dart:convert';
import 'package:http/http.dart' as http;

import 'game_config.dart';
import 'model.dart';

class LoadGames {

  static String permittedResponseFields = 'name,maxplayers,minplayers,maxplaytime,image,thumbnail';

  static Future<Games> fetchGames(Settings settings, List<Item> items) async {
    Games games = new Games(games: new List<Game>());
    Map<String, String> requestHeaders = {
      'Bgg-Filter-Player-Count': settings.playerCount.toString(),
      'Bgg-Filter-Min-Duration': settings.minTime.toString(),
      'Bgg-Filter-Max-Duration': settings.maxTime.toString(),
      'Bgg-Field-Whitelist': permittedResponseFields
    };
    for (Item item in items) {
      var response = await http.get(
          "${GameConfig.boardGameGeekProxyUrl}/${item.itemType.name}/${item
              .name}",
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
  final List<Game> games;

  Games({this.games});

  factory Games.fromJson(List<dynamic> parsedJson) {
    List<Game> games = new List<Game>();

    games = parsedJson.map((i) => Game.fromJson(i)).toList();

    return new Games(
      games: games,
    );
  }

  Games addGames(Games newGames) {
    games.addAll(newGames.games);
    return this;
  }
}

class Game {
  final String name;
  final int maxPlayers;
  final int minPlayers;
  final int maxPlaytime;
  final String imageUrl;
  final String thumbnailUrl;

  Game({this.name,
    this.maxPlayers,
    this.minPlayers,
    this.maxPlaytime,
    this.imageUrl,
    this.thumbnailUrl});

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      name: json['name'],
      maxPlayers: json['maxplayers'],
      minPlayers: json['minplayers'],
      maxPlaytime: json['maxplaytime'],
      imageUrl: json['image'],
      thumbnailUrl: json['thumbnail'],
    );
  }
}
