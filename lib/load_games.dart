import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'game_config.dart';
import 'model.dart';

class LoadGames {
  static String permittedResponseFields =
      'name,maxplayers,minplayers,maxplaytime,image,thumbnail,stats';

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

  List<Game> getGamesByRating() {
    List<Game> sortedGames = List<Game>.from(games);
    sortedGames.sort((a, b) => b.averageRating.compareTo(a.averageRating));
    return sortedGames;
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
    debugPrint(json['stats']);
    debugPrint(json['stats']['average']);
    return Game(
      name: json['name'],
      maxPlayers: json['maxplayers'],
      minPlayers: json['minplayers'],
      maxPlaytime: json['maxplaytime'],
      imageUrl: json['image'],
      thumbnailUrl: json['thumbnail'],
      averageRating: double.tryParse(json['stats']['average'] ?? "0") ?? 0,
    );
  }
}
