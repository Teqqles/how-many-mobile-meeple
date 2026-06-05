import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:how_many_mobile_meeple/model/settings.dart';

import 'app_common.dart';
import 'package:how_many_mobile_meeple/model/item.dart';

import 'model/game.dart';
import 'model/games.dart';

class LoadGames {
  static Future<Games> fetchGames(Settings settings, List<Item> items) async {
    Games games = Games(gamesByName: Map<String, Game>());
    Map<String, String> requestHeaders = Map.fromEntries(
        settings.enabledSettings.entries
            .where((entry) => entry.value.header != null)
            .map((entry) => MapEntry(entry.value.header!, entry.value.value.toString())));

    // Create parallel HTTP requests for all items
    final futures = items.map((item) async {
      final itemName = Uri.encodeComponent(item.name);
      var response = await http.get(
        Uri.parse("${AppCommon.boardGameGeekProxyUrl}/${item.itemType.name}/$itemName"),
          headers: requestHeaders.map((k, v) => MapEntry(k, v.toString())));

      if (response.statusCode != 200) {
        throw Exception('Failed to load games for ${item.name}');
      }

      return response;
    });

    // Wait for all requests to complete in parallel
    final responses = await Future.wait(futures);

    // Process all responses
    for (var response in responses) {
      Games loadedGames = Games.fromJson(jsonDecode(response.body));
      games.addGames(loadedGames);
    }

    return games;
  }
}