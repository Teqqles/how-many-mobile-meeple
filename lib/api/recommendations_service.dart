import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:how_many_mobile_meeple/app_common.dart';
import 'package:how_many_mobile_meeple/model/recommendation.dart';

class _CachedRecommendations {
  final List<Recommendation> recommendations;
  final int timestamp;

  _CachedRecommendations(this.recommendations, this.timestamp);

  bool get isStale =>
      DateTime.now().millisecondsSinceEpoch - timestamp > _cacheDurationMs;

  static const int _cacheDurationMs = 30 * 60 * 1000;
}

class RecommendationsService {
  static http.Client? _testClient;
  static final Map<String, _CachedRecommendations> _cache = {};
  static final Map<String, Future<List<Recommendation>>> _inFlight = {};

  static void setTestClient(http.Client client) => _testClient = client;
  static void resetTestClient() {
    _testClient = null;
    _cache.clear();
    _inFlight.clear();
  }

  static Future<List<Recommendation>> fetchRecommendations({
    required List<int> gameIds,
    required Map<String, String> headers,
    int limit = 10,
    List<int> excludeIds = const [],
  }) {
    final key = (gameIds.toList()..sort()).join(',');
    final cached = _cache[key];
    if (cached != null && !cached.isStale) {
      return Future.value(cached.recommendations);
    }
    return _inFlight[key] ??= _doFetch(
      gameIds: gameIds,
      headers: headers,
      limit: limit,
      excludeIds: excludeIds,
      key: key,
    );
  }

  static Future<List<Recommendation>> _doFetch({
    required List<int> gameIds,
    required Map<String, String> headers,
    required int limit,
    required List<int> excludeIds,
    required String key,
  }) async {
    final url = Uri.parse(
        '${AppCommon.boardGameGeekProxyUrl}/recommendations/from-games');
    final client = _testClient ?? http.Client();

    try {
      final response = await client.post(
        url,
        headers: {
          ...headers,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'game_ids': gameIds,
          'limit': limit,
          'exclude_ids': excludeIds,
        }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final list = body['recommendations'] as List<dynamic>;
        final results = list.map((r) => Recommendation.fromJson(r)).toList();
        _cache[key] = _CachedRecommendations(
            results, DateTime.now().millisecondsSinceEpoch);
        return results;
      }

      throw Exception('Failed to load recommendations');
    } finally {
      _inFlight.remove(key);
      if (_testClient == null) client.close();
    }
  }
}
