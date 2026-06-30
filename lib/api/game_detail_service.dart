import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:how_many_mobile_meeple/app_common.dart';
import 'package:how_many_mobile_meeple/model/game.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';

class _CachedGame {
  final Game game;
  final int timestamp;

  _CachedGame(this.game, this.timestamp);

  bool get isStale => GameDetailService._nowMs() - timestamp > _cacheDurationMs;

  static const int _cacheDurationMs = 30 * 60 * 1000;
}

class GameDetailService {
  static final Map<int, _CachedGame> _cache = {};
  static final Map<int, Future<Game>> _inFlight = {};
  static http.Client? _testClient;
  static int Function() _nowMs = () => DateTime.now().millisecondsSinceEpoch;

  static void setTestClient(http.Client client) => _testClient = client;
  static void resetTestClient() {
    _testClient = null;
    _cache.clear();
    _inFlight.clear();
    _nowMs = () => DateTime.now().millisecondsSinceEpoch;
  }

  static Future<Game> fetchGame(int gameId) {
    final cached = _cache[gameId];
    if (cached != null && !cached.isStale) return Future.value(cached.game);
    return _inFlight[gameId] ??= _doFetch(gameId);
  }

  static Future<Game> _doFetch(int gameId) async {
    final url = Uri.parse('${AppCommon.boardGameGeekProxyUrl}/game/$gameId');
    final client = _testClient ?? http.Client();

    try {
      final response = await client.get(url, headers: {
        Settings.fieldsToReturnFromApi.header!:
            Settings.fieldsToReturnFromApi.value.toString(),
      });

      if (response.statusCode == 200) {
        final game = Game.fromJson(jsonDecode(response.body));
        _cache[gameId] = _CachedGame(game, _nowMs());
        return game;
      }

      throw Exception('Failed to load game $gameId');
    } finally {
      _inFlight.remove(gameId);
      if (_testClient == null) client.close();
    }
  }
}
