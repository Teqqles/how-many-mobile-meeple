import 'dart:convert';
import 'package:http/http.dart' as http;

import 'app_common.dart';
import 'package:how_many_mobile_meeple/model/game_request.dart';
import 'package:how_many_mobile_meeple/model/item.dart';
import 'model/game.dart';
import 'model/games.dart';

class LoadGames {
  static const int _initialBackoffSeconds = 2;
  static const int _maxBackoffSeconds = 30;
  static const Duration _retryTimeout = Duration(seconds: 600);

  static Future<Games> fetchGames(GameRequest request) async {
    Games games = Games(gamesByName: Map<String, Game>());

    final futures = request.items.itemList
        .map((item) => _fetchWithRetry(item, request.headers));
    final responses = await Future.wait(futures);

    for (var response in responses) {
      Games loadedGames = Games.fromJson(jsonDecode(response.body));
      games.addGames(loadedGames);
    }

    return games;
  }

  static Future<http.Response> _fetchWithRetry(
      Item item, Map<String, String> headers) async {
    final url = item.itemType == ItemType.hotList
        ? Uri.parse("${AppCommon.boardGameGeekProxyUrl}/hot")
        : Uri.parse(
            "${AppCommon.boardGameGeekProxyUrl}/${item.itemType.name}/${Uri.encodeComponent(item.name)}");
    final deadline = DateTime.now().add(_retryTimeout);
    int backoff = _initialBackoffSeconds;

    while (true) {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) return response;

      if (response.statusCode == 202 && DateTime.now().isBefore(deadline)) {
        await Future.delayed(Duration(seconds: backoff));
        backoff = (backoff * 2).clamp(0, _maxBackoffSeconds);
        continue;
      }

      final source = item.itemType == ItemType.hotList
          ? 'trending games'
          : '${item.itemType.name} "${item.name}"';
      throw Exception('Failed to load $source');
    }
  }
}
