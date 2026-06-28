import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:how_many_mobile_meeple/api/http_retry_client.dart';
import 'package:how_many_mobile_meeple/api/plays_service.dart';

void main() {
  setUp(() {
    PlaysService.clearCache();
    HttpRetryClient.setDelayFunction((_) async {});
  });

  tearDown(() {
    HttpRetryClient.resetTestClient();
    HttpRetryClient.resetDelayFunction();
    PlaysService.clearCache();
  });

  group('PlaysService.fetchPlays', () {
    test('parses play data from API response', () async {
      final responseBody = jsonEncode([
        {'game_id': 1, 'game_name': 'Wingspan', 'total_plays': 5},
        {'game_id': 2, 'game_name': 'Catan', 'total_plays': 12},
      ]);

      HttpRetryClient.setTestClient(
        http_testing.MockClient((request) async {
          return http.Response(responseBody, 200);
        }),
      );

      final plays = await PlaysService.fetchPlays('testuser');

      expect(plays.length, 2);
      expect(plays[1]!.gameName, 'Wingspan');
      expect(plays[1]!.totalPlays, 5);
      expect(plays[2]!.gameName, 'Catan');
      expect(plays[2]!.totalPlays, 12);
    });

    test('returns map keyed by game_id', () async {
      final responseBody = jsonEncode([
        {'game_id': 42, 'game_name': 'Azul', 'total_plays': 3},
      ]);

      HttpRetryClient.setTestClient(
        http_testing.MockClient((request) async {
          return http.Response(responseBody, 200);
        }),
      );

      final plays = await PlaysService.fetchPlays('testuser');

      expect(plays.containsKey(42), isTrue);
      expect(plays[42]!.gameName, 'Azul');
    });

    test('returns empty map on 404', () async {
      HttpRetryClient.setTestClient(
        http_testing.MockClient((request) async {
          return http.Response('not found', 404);
        }),
      );

      final plays = await PlaysService.fetchPlays('nonexistent');

      expect(plays, isEmpty);
    });

    test('throws exception on server error', () async {
      HttpRetryClient.setTestClient(
        http_testing.MockClient((request) async {
          return http.Response('error', 500);
        }),
      );

      expect(
        () => PlaysService.fetchPlays('testuser'),
        throwsException,
      );
    });

    test('calls correct URL with username', () async {
      Uri? capturedUrl;
      HttpRetryClient.setTestClient(
        http_testing.MockClient((request) async {
          capturedUrl = request.url;
          return http.Response('[]', 200);
        }),
      );

      await PlaysService.fetchPlays('teqqles');

      expect(capturedUrl!.path, '/plays/teqqles');
    });

    test('uses cached result on subsequent calls', () async {
      int callCount = 0;
      HttpRetryClient.setTestClient(
        http_testing.MockClient((request) async {
          callCount++;
          return http.Response(
            jsonEncode([
              {'game_id': 1, 'game_name': 'Wingspan', 'total_plays': 5}
            ]),
            200,
          );
        }),
      );

      await PlaysService.fetchPlays('testuser');
      await PlaysService.fetchPlays('testuser');

      expect(callCount, 1);
    });

    test('caches per username separately', () async {
      int callCount = 0;
      HttpRetryClient.setTestClient(
        http_testing.MockClient((request) async {
          callCount++;
          return http.Response('[]', 200);
        }),
      );

      await PlaysService.fetchPlays('user1');
      await PlaysService.fetchPlays('user2');

      expect(callCount, 2);
    });

    test('retries on 202 before succeeding', () async {
      int callCount = 0;
      HttpRetryClient.setTestClient(
        http_testing.MockClient((request) async {
          callCount++;
          if (callCount < 2) {
            return http.Response('processing', 202);
          }
          return http.Response(
            jsonEncode([
              {'game_id': 1, 'game_name': 'Wingspan', 'total_plays': 5}
            ]),
            200,
          );
        }),
      );

      final plays = await PlaysService.fetchPlays('testuser');

      expect(plays.length, 1);
      expect(callCount, 2);
    });

    test('handles empty plays array', () async {
      HttpRetryClient.setTestClient(
        http_testing.MockClient((request) async {
          return http.Response('[]', 200);
        }),
      );

      final plays = await PlaysService.fetchPlays('newuser');

      expect(plays, isEmpty);
    });

    test('clearCache forces re-fetch', () async {
      int callCount = 0;
      HttpRetryClient.setTestClient(
        http_testing.MockClient((request) async {
          callCount++;
          return http.Response('[]', 200);
        }),
      );

      await PlaysService.fetchPlays('testuser');
      PlaysService.clearCache();
      await PlaysService.fetchPlays('testuser');

      expect(callCount, 2);
    });
  });
}
