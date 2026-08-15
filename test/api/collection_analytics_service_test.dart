@Tags(['unit'])
library;

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:how_many_mobile_meeple/api/collection_analytics_service.dart';
import 'package:how_many_mobile_meeple/api/http_retry_client.dart';
import '../helpers/sync_mock_client.dart';

String _body() => jsonEncode({
      'summary': {'average_weight': 2.3},
      'playtime_distribution': [
        {'label': 'short [30, 60)', 'count': 32}
      ],
      'player_count_coverage': [
        {'player_count': 4, 'best_or_recommended': 99}
      ],
    });

void main() {
  setUp(() => HttpRetryClient.setDelayFunction((_) => Future.value()));
  tearDown(() {
    HttpRetryClient.resetTestClient();
    HttpRetryClient.resetDelayFunction();
  });

  group('CollectionAnalyticsService.fetch — Right', () {
    test('200 with valid body returns a populated model', () async {
      HttpRetryClient.setTestClient(
          SyncMockClient((_) => http.Response(_body(), 200)));
      final a = await CollectionAnalyticsService.fetch('teqqles');
      expect(a, isNotNull);
      expect(a!.mostCoveredPlayerCount, 4);
      expect(a.averageWeight, 2.3);
      expect(a.dominantPlaytime!.min, 30);
    });
  });

  group('CollectionAnalyticsService.fetch — Cross-check', () {
    test('calls the correctly-encoded analytics URL', () async {
      Uri? captured;
      HttpRetryClient.setTestClient(SyncMockClient((req) {
        captured = req.url;
        return http.Response(_body(), 200);
      }));
      await CollectionAnalyticsService.fetch('a b');
      expect(captured!.path, '/collection/a%20b/analytics');
    });
  });

  group('CollectionAnalyticsService.fetch — Boundary', () {
    test('200 with empty sections returns model with null fields', () async {
      HttpRetryClient.setTestClient(SyncMockClient(
          (_) => http.Response(jsonEncode({'summary': {}}), 200)));
      final a = await CollectionAnalyticsService.fetch('teqqles');
      expect(a, isNotNull);
      expect(a!.mostCoveredPlayerCount, isNull);
    });
  });

  group('CollectionAnalyticsService.fetch — Error', () {
    test('non-200 returns null', () async {
      HttpRetryClient.setTestClient(
          SyncMockClient((_) => http.Response('nope', 404)));
      expect(await CollectionAnalyticsService.fetch('teqqles'), isNull);
    });

    test('invalid JSON returns null', () async {
      HttpRetryClient.setTestClient(
          SyncMockClient((_) => http.Response('not json', 200)));
      expect(await CollectionAnalyticsService.fetch('teqqles'), isNull);
    });

    test('non-map JSON returns null', () async {
      HttpRetryClient.setTestClient(
          SyncMockClient((_) => http.Response('[1,2,3]', 200)));
      expect(await CollectionAnalyticsService.fetch('teqqles'), isNull);
    });

    test('thrown client error returns null', () async {
      HttpRetryClient.setTestClient(SyncMockClient((_) {
        throw Exception('network down');
      }));
      expect(await CollectionAnalyticsService.fetch('teqqles'), isNull);
    });
  });
}
