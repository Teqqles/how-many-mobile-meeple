import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:how_many_mobile_meeple/app_common.dart';
import 'package:how_many_mobile_meeple/model/game.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';

class _CachedGame {
  final Game game;
  final int timestamp;

  _CachedGame(this.game, this.timestamp);

  bool get isStale =>
      DateTime.now().millisecondsSinceEpoch - timestamp > _cacheDurationMs;

  static const int _cacheDurationMs = 30 * 60 * 1000;
}

class GameDetailService {
  static final Map<int, _CachedGame> _cache = {};

  static Future<Game> fetchGame(int gameId) async {
    final cached = _cache[gameId];
    if (cached != null && !cached.isStale) {
      return cached.game;
    }

    final url = Uri.parse('${AppCommon.boardGameGeekProxyUrl}/game/$gameId');

    final response = await http.get(url, headers: {
      Settings.fieldsToReturnFromApi.header!:
          Settings.fieldsToReturnFromApi.value.toString(),
    });

    if (response.statusCode == 200) {
      final game = Game.fromJson(jsonDecode(response.body));
      _cache[gameId] = _CachedGame(game, DateTime.now().millisecondsSinceEpoch);
      return game;
    }

    throw Exception('Failed to load game $gameId');
  }
}
