@Tags(['unit'])
library;

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:how_many_mobile_meeple/api/http_retry_client.dart';
import 'package:how_many_mobile_meeple/api/plays_service.dart';
import '../helpers/sync_mock_client.dart';

String _wrapResponse(List<Map<String, dynamic>> plays,
    {bool complete = true, int? retryAfterSeconds}) {
  final meta = <String, dynamic>{'complete': complete};
  if (retryAfterSeconds != null) {
    meta['retry_after_seconds'] = retryAfterSeconds;
  }
  return jsonEncode({'plays': plays, 'meta': meta});
}

void main() {
  setUp(() {
    PlaysService.clearCache();
    HttpRetryClient.setDelayFunction((_) => Future.value());
  });

  tearDown(() {
    HttpRetryClient.resetTestClient();
    HttpRetryClient.resetDelayFunction();
    PlaysService.clearCache();
  });

  group('PlaysService.fetchPlays', () {
    test('parses play data from API response', () async {
      final responseBody = _wrapResponse([
        {'game_id': 1, 'game_name': 'Wingspan', 'total_plays': 5},
        {'game_id': 2, 'game_name': 'Catan', 'total_plays': 12},
      ]);

      HttpRetryClient.setTestClient(
        SyncMockClient((_) => http.Response(responseBody, 200)),
      );

      final result = await PlaysService.fetchPlays('testuser');

      expect(result.plays.length, 2);
      expect(result.plays[1]!.gameName, 'Wingspan');
      expect(result.plays[1]!.totalPlays, 5);
      expect(result.plays[2]!.gameName, 'Catan');
      expect(result.plays[2]!.totalPlays, 12);
    });

    test('returns map keyed by game_id', () async {
      final responseBody = _wrapResponse([
        {'game_id': 42, 'game_name': 'Azul', 'total_plays': 3},
      ]);

      HttpRetryClient.setTestClient(
        SyncMockClient((_) => http.Response(responseBody, 200)),
      );

      final result = await PlaysService.fetchPlays('testuser');

      expect(result.plays.containsKey(42), isTrue);
      expect(result.plays[42]!.gameName, 'Azul');
    });

    test('returns empty map on 404', () async {
      HttpRetryClient.setTestClient(
        SyncMockClient((_) => http.Response('not found', 404)),
      );

      final result = await PlaysService.fetchPlays('nonexistent');

      expect(result.plays, isEmpty);
      expect(result.complete, isTrue);
    });

    test('throws exception on server error', () async {
      HttpRetryClient.setTestClient(
        SyncMockClient((_) => http.Response('error', 500)),
      );

      expect(
        () => PlaysService.fetchPlays('testuser'),
        throwsException,
      );
    });

    test('calls correct URL with username', () async {
      Uri? capturedUrl;
      HttpRetryClient.setTestClient(
        SyncMockClient((request) {
          capturedUrl = request.url;
          return http.Response(_wrapResponse([]), 200);
        }),
      );

      await PlaysService.fetchPlays('teqqles');

      expect(capturedUrl!.path, '/plays/teqqles');
    });

    test('sends Bgg-Plays-Meta header', () async {
      Map<String, String>? capturedHeaders;
      HttpRetryClient.setTestClient(
        SyncMockClient((request) {
          capturedHeaders = request.headers;
          return http.Response(_wrapResponse([]), 200);
        }),
      );

      await PlaysService.fetchPlays('testuser');

      expect(capturedHeaders!['Bgg-Plays-Meta'], 'true');
    });

    test('uses cached result on subsequent calls when complete', () async {
      int callCount = 0;
      HttpRetryClient.setTestClient(
        SyncMockClient((_) {
          callCount++;
          return http.Response(
            _wrapResponse([
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

    test('does not cache incomplete results', () async {
      int callCount = 0;
      HttpRetryClient.setTestClient(
        SyncMockClient((_) {
          callCount++;
          return http.Response(
            _wrapResponse(
              [
                {'game_id': 1, 'game_name': 'Wingspan', 'total_plays': 5}
              ],
              complete: false,
              retryAfterSeconds: 30,
            ),
            200,
          );
        }),
      );

      await PlaysService.fetchPlays('testuser');
      await PlaysService.fetchPlays('testuser');

      expect(callCount, 2);
    });

    test('caches per username separately', () async {
      int callCount = 0;
      HttpRetryClient.setTestClient(
        SyncMockClient((_) {
          callCount++;
          return http.Response(_wrapResponse([]), 200);
        }),
      );

      await PlaysService.fetchPlays('user1');
      await PlaysService.fetchPlays('user2');

      expect(callCount, 2);
    });

    test('retries on 202 before succeeding', () async {
      int callCount = 0;
      HttpRetryClient.setTestClient(
        SyncMockClient((_) {
          callCount++;
          if (callCount < 2) {
            return http.Response('processing', 202);
          }
          return http.Response(
            _wrapResponse([
              {'game_id': 1, 'game_name': 'Wingspan', 'total_plays': 5}
            ]),
            200,
          );
        }),
      );

      final result = await PlaysService.fetchPlays('testuser');

      expect(result.plays.length, 1);
      expect(callCount, 2);
    });

    test('handles empty plays array', () async {
      HttpRetryClient.setTestClient(
        SyncMockClient((_) => http.Response(_wrapResponse([]), 200)),
      );

      final result = await PlaysService.fetchPlays('newuser');

      expect(result.plays, isEmpty);
      expect(result.complete, isTrue);
    });

    test('clearCache forces re-fetch', () async {
      int callCount = 0;
      HttpRetryClient.setTestClient(
        SyncMockClient((_) {
          callCount++;
          return http.Response(_wrapResponse([]), 200);
        }),
      );

      await PlaysService.fetchPlays('testuser');
      PlaysService.clearCache();
      await PlaysService.fetchPlays('testuser');

      expect(callCount, 2);
    });

    test('returns complete true when meta indicates complete', () async {
      HttpRetryClient.setTestClient(
        SyncMockClient((_) => http.Response(
            _wrapResponse([
              {'game_id': 1, 'game_name': 'Azul', 'total_plays': 3}
            ]),
            200)),
      );

      final result = await PlaysService.fetchPlays('testuser');

      expect(result.complete, isTrue);
      expect(result.retryAfterSeconds, 0);
    });

    test('returns incomplete with retry delay when meta indicates more data',
        () async {
      HttpRetryClient.setTestClient(
        SyncMockClient((_) => http.Response(
            _wrapResponse(
              [
                {'game_id': 1, 'game_name': 'Azul', 'total_plays': 3}
              ],
              complete: false,
              retryAfterSeconds: 30,
            ),
            200)),
      );

      final result = await PlaysService.fetchPlays('testuser');

      expect(result.complete, isFalse);
      expect(result.retryAfterSeconds, 30);
      expect(result.plays.length, 1);
    });
  });
}
