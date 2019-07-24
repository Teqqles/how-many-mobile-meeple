import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:how_many_mobile_meeple/model/settings.dart';

import 'game_config.dart';
import 'package:how_many_mobile_meeple/model/item.dart';

import 'model/game.dart';
import 'model/games.dart';

class LoadGames {
  static Future<Games> fetchGames(Settings settings, List<Item> items) async {
    Games games = new Games(gamesByName: Map<String, Game>());
    Map<String, String> requestHeaders = settings.enabledSettings.map(
        (_, setting) => MapEntry(setting.header, setting.value.toString()));
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