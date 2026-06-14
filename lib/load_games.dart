import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:how_many_mobile_meeple/model/settings.dart';

import 'app_common.dart';
import 'package:how_many_mobile_meeple/model/item.dart';

import 'model/game.dart';
import 'model/games.dart';

class LoadGames {
  static const Duration _retryInterval = Duration(seconds: 10);
  static const Duration _retryTimeout = Duration(seconds: 60);

  static Future<Games> fetchGames(Settings settings, List<Item> items) async {
    Games games = Games(gamesByName: Map<String, Game>());
    Map<String, String> requestHeaders = Map.fromEntries(settings
        .enabledSettings.entries
        .where((entry) => entry.value.header != null)
        .map((entry) =>
            MapEntry(entry.value.header!, entry.value.value.toString())));

    final futures = items.map((item) => _fetchWithRetry(item, requestHeaders));
    final responses = await Future.wait(futures);

    for (var response in responses) {
      Games loadedGames = Games.fromJson(jsonDecode(response.body));
      games.addGames(loadedGames);
    }

    return games;
  }

  static Future<http.Response> _fetchWithRetry(
      Item item, Map<String, String> headers) async {
    final url = Uri.parse(
        "${AppCommon.boardGameGeekProxyUrl}/${item.itemType.name}/${Uri.encodeComponent(item.name)}");
    final deadline = DateTime.now().add(_retryTimeout);

    while (true) {
      final response = await http.get(url,
          headers: headers.map((k, v) => MapEntry(k, v.toString())));

      if (response.statusCode == 200) return response;

      if (response.statusCode == 202 && DateTime.now().isBefore(deadline)) {
        await Future.delayed(_retryInterval);
        continue;
      }

      throw Exception('Failed to load games for ${item.name}');
    }
  }
}
