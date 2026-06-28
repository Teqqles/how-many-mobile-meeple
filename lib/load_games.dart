import 'dart:convert';
import 'package:http/http.dart' as http;

import 'api/http_retry_client.dart';
import 'app_common.dart';
import 'package:how_many_mobile_meeple/model/game_request.dart';
import 'package:how_many_mobile_meeple/model/item.dart';
import 'model/game.dart';
import 'model/games.dart';

class LoadGames {
  static Future<Games> fetchGames(GameRequest request) async {
    Games games = Games(gamesByName: Map<String, Game>());

    final futures =
        request.items.itemList.map((item) => _fetchItem(item, request.headers));
    final responses = await Future.wait(futures);

    for (var response in responses) {
      Games loadedGames = Games.fromJson(jsonDecode(response.body));
      games.addGames(loadedGames);
    }

    return games;
  }

  static Future<http.Response> _fetchItem(
      Item item, Map<String, String> headers) async {
    final url = item.itemType == ItemType.hotList
        ? Uri.parse("${AppCommon.boardGameGeekProxyUrl}/hot")
        : Uri.parse(
            "${AppCommon.boardGameGeekProxyUrl}/${item.itemType.name}/${Uri.encodeComponent(item.name)}");

    final response = await HttpRetryClient.getWithRetry(url, headers: headers);

    if (response.statusCode == 200) return response;

    final source = item.itemType == ItemType.hotList
        ? 'trending games'
        : '${item.itemType.name} "${item.name}"';
    throw Exception('Failed to load $source');
  }
}
