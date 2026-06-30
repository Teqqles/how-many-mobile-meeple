@Tags(['unit'])
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:how_many_mobile_meeple/api/game_detail_service.dart';
import 'package:how_many_mobile_meeple/model/game.dart';
import '../helpers/sync_mock_client.dart';

final _gameJson = json.encode({
  'id': 42,
  'name': 'Wingspan',
  'maxplayers': 5,
  'minplayers': 1,
  'maxplaytime': 70,
  'image': 'http://example.com/img.jpg',
  'stats': {
    'average': 8.1,
    'averageweight': 2.4,
  },
});

void main() {
  tearDown(() {
    GameDetailService.resetTestClient();
  });

  group('GameDetailService.fetchGame', () {
    test('returns a Game on 200', () async {
      GameDetailService.setTestClient(
        SyncMockClient((_) => http.Response(_gameJson, 200)),
      );

      final game = await GameDetailService.fetchGame(42);

      expect(game, isA<Game>());
      expect(game.name, 'Wingspan');
      expect(game.id, 42);
    });

    test('throws on non-200 response', () async {
      GameDetailService.setTestClient(
        SyncMockClient((_) => http.Response('not found', 404)),
      );

      expect(
        () => GameDetailService.fetchGame(999),
        throwsException,
      );
    });

    test('returns cached result on subsequent calls', () async {
      int callCount = 0;
      GameDetailService.setTestClient(
        SyncMockClient((_) {
          callCount++;
          return http.Response(_gameJson, 200);
        }),
      );

      await GameDetailService.fetchGame(42);
      await GameDetailService.fetchGame(42);

      expect(callCount, 1);
    });

    test('sends correct headers', () async {
      Map<String, String>? capturedHeaders;
      GameDetailService.setTestClient(
        SyncMockClient((request) {
          capturedHeaders = request.headers;
          return http.Response(_gameJson, 200);
        }),
      );

      await GameDetailService.fetchGame(42);

      expect(capturedHeaders, isNotNull);
      expect(capturedHeaders!.containsKey('bgg-field-whitelist'), true);
    });

    test('deduplicates concurrent requests for same game', () async {
      int callCount = 0;
      GameDetailService.setTestClient(
        SyncMockClient((_) {
          callCount++;
          return http.Response(_gameJson, 200);
        }),
      );

      final results = await Future.wait([
        GameDetailService.fetchGame(42),
        GameDetailService.fetchGame(42),
        GameDetailService.fetchGame(42),
      ]);

      expect(callCount, 1);
      expect(results[0].name, 'Wingspan');
      expect(results[1].name, 'Wingspan');
    });

    test('different game IDs fetch independently', () async {
      int callCount = 0;
      GameDetailService.setTestClient(
        SyncMockClient((request) {
          callCount++;
          final id = int.parse(request.url.pathSegments.last);
          return http.Response(
            json.encode({
              'id': id,
              'name': 'Game $id',
              'maxplayers': 4,
              'minplayers': 2,
              'maxplaytime': 60,
              'image': '',
              'stats': {'average': 7.0, 'averageweight': 2.0},
            }),
            200,
          );
        }),
      );

      final game1 = await GameDetailService.fetchGame(1);
      final game2 = await GameDetailService.fetchGame(2);

      expect(callCount, 2);
      expect(game1.name, 'Game 1');
      expect(game2.name, 'Game 2');
    });

    test('clears in-flight map after completion', () async {
      int callCount = 0;
      GameDetailService.setTestClient(
        SyncMockClient((_) {
          callCount++;
          return http.Response(_gameJson, 200);
        }),
      );

      await GameDetailService.fetchGame(42);
      GameDetailService.resetTestClient();

      GameDetailService.setTestClient(
        SyncMockClient((_) {
          callCount++;
          return http.Response(_gameJson, 200);
        }),
      );

      await GameDetailService.fetchGame(42);
      expect(callCount, 2);
    });
  });
}
