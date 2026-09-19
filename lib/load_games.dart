import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api/http_retry_client.dart';
import 'app_common.dart';

import 'package:how_many_mobile_meeple/model/game_request.dart';
import 'package:how_many_mobile_meeple/model/item.dart';

import 'model/game.dart';
import 'model/game_sources.dart';
import 'model/games.dart';

class LoadGames {
  static Future<Games> fetchGames(GameRequest request) async =>
      (await fetchGamesWithSources(request)).games;

  /// Fetches the pool and, alongside it, a [GameSources] map recording which
  /// source each game came from - built here because the merged pool keys games
  /// by name and loses that origin. Sources are recorded in the order they were
  /// requested so [GameSources] can apply its collection-before-geeklist,
  /// add-order-then rule.
  static Future<({Games games, GameSources sources})> fetchGamesWithSources(
    GameRequest request,
  ) async {
    Games games = Games(gamesByName: Map<String, Game>());

    final items = request.items.itemList;
    final responses = await Future.wait(
      items.map((item) => _fetchItem(item, request.headers)),
    );

    final loaded = <({Item item, List<Game> games})>[];
    for (var i = 0; i < items.length; i++) {
      final loadedGames = Games.fromJson(jsonDecode(responses[i].body));
      games.addGames(loadedGames);
      loaded.add((item: items[i], games: loadedGames.games));
    }

    return (games: games, sources: GameSources.fromSources(loaded));
  }

  static Future<http.Response> _fetchItem(
    Item item,
    Map<String, String> headers,
  ) async {
    final url = item.itemType == ItemType.hotList
        ? Uri.parse("${AppCommon.boardGameGeekProxyUrl}/hot")
        : Uri.parse(
            "${AppCommon.boardGameGeekProxyUrl}/${item.itemType.name}/${Uri.encodeComponent(item.name)}",
          );

    final response = await HttpRetryClient.getWithRetry(url, headers: headers);

    if (response.statusCode == 200) return response;

    final source = item.itemType == ItemType.hotList
        ? 'trending games'
        : '${item.itemType.name} "${item.name}"';
    throw Exception('Failed to load $source');
  }
}
