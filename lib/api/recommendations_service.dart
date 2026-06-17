import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:how_many_mobile_meeple/app_common.dart';
import 'package:how_many_mobile_meeple/model/recommendation.dart';

class RecommendationsService {
  static Future<List<Recommendation>> fetchRecommendations({
    required List<int> gameIds,
    required Map<String, String> headers,
    int limit = 10,
    List<int> excludeIds = const [],
  }) async {
    final url = Uri.parse(
        '${AppCommon.boardGameGeekProxyUrl}/recommendations/from-games');

    final response = await http.post(
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
      return list.map((r) => Recommendation.fromJson(r)).toList();
    }

    throw Exception('Failed to load recommendations');
  }
}
