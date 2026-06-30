@Tags(['unit'])
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:how_many_mobile_meeple/api/recommendations_service.dart';
import 'package:how_many_mobile_meeple/model/recommendation.dart';
import '../helpers/sync_mock_client.dart';

void main() {
  tearDown(() {
    RecommendationsService.resetTestClient();
  });

  group('RecommendationsService.fetchRecommendations', () {
    test('returns list of Recommendations on 200', () async {
      RecommendationsService.setTestClient(
        SyncMockClient((_) => http.Response(
              json.encode({
                'recommendations': [
                  {
                    'game_id': 1,
                    'name': 'Everdell',
                    'similarity_score': 0.85,
                  },
                  {
                    'game_id': 2,
                    'name': 'Ark Nova',
                    'similarity_score': 0.72,
                  },
                ]
              }),
              200,
            )),
      );

      final results = await RecommendationsService.fetchRecommendations(
        gameIds: [42],
        headers: {},
      );

      expect(results, hasLength(2));
      expect(results[0], isA<Recommendation>());
      expect(results[0].name, 'Everdell');
      expect(results[0].similarityScore, 0.85);
      expect(results[1].name, 'Ark Nova');
    });

    test('throws on non-200 response', () async {
      RecommendationsService.setTestClient(
        SyncMockClient((_) => http.Response('server error', 500)),
      );

      expect(
        () => RecommendationsService.fetchRecommendations(
          gameIds: [42],
          headers: {},
        ),
        throwsException,
      );
    });

    test('sends game_ids, limit, and exclude_ids in body', () async {
      Map<String, dynamic>? capturedBody;
      RecommendationsService.setTestClient(
        SyncMockClient((request) {
          capturedBody = json.decode(request.url.toString().contains('/')
              ? (request as http.Request).body
              : '{}');
          return http.Response(
            json.encode({'recommendations': []}),
            200,
          );
        }),
      );

      await RecommendationsService.fetchRecommendations(
        gameIds: [1, 2, 3],
        headers: {'X-Custom': 'val'},
        limit: 5,
        excludeIds: [10],
      );

      expect(capturedBody!['game_ids'], [1, 2, 3]);
      expect(capturedBody!['limit'], 5);
      expect(capturedBody!['exclude_ids'], [10]);
    });

    test('merges custom headers with content-type', () async {
      Map<String, String>? capturedHeaders;
      RecommendationsService.setTestClient(
        SyncMockClient((request) {
          capturedHeaders = request.headers;
          return http.Response(
            json.encode({'recommendations': []}),
            200,
          );
        }),
      );

      await RecommendationsService.fetchRecommendations(
        gameIds: [1],
        headers: {'X-Custom': 'test'},
      );

      expect(capturedHeaders!['x-custom'], 'test');
      expect(capturedHeaders!['content-type'], contains('application/json'));
    });
  });
}
