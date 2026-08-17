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
    {'label': 'short [30, 60)', 'count': 32},
  ],
  'player_count_coverage': [
    {'player_count': 4, 'best_or_recommended': 99},
  ],
});

void main() {
  setUp(() => HttpRetryClient.setDelayFunction((_) => Future.value()));
  tearDown(() {
    HttpRetryClient.resetTestClient();
    HttpRetryClient.resetDelayFunction();
  });

  group('CollectionAnalyticsService.fetch — Right', () {
    test(
      '200 with valid body returns a populated model, not retryable',
      () async {
        HttpRetryClient.setTestClient(
          SyncMockClient((_) => http.Response(_body(), 200)),
        );
        final r = await CollectionAnalyticsService.fetch('teqqles');
        expect(r.analytics, isNotNull);
        expect(r.analytics!.mostCoveredPlayerCount, 4);
        expect(r.analytics!.averageWeight, 2.3);
        expect(r.analytics!.dominantPlaytime!.min, 30);
        expect(r.retryable, isFalse);
      },
    );
  });

  group('CollectionAnalyticsService.fetch — Cross-check', () {
    test('calls the correctly-encoded analytics URL', () async {
      Uri? captured;
      HttpRetryClient.setTestClient(
        SyncMockClient((req) {
          captured = req.url;
          return http.Response(_body(), 200);
        }),
      );
      await CollectionAnalyticsService.fetch('a b');
      expect(captured!.path, '/collection/a%20b/analytics');
    });
  });

  group('CollectionAnalyticsService.fetch — Boundary', () {
    test(
      '200 with empty sections returns null fields and is retryable',
      () async {
        HttpRetryClient.setTestClient(
          SyncMockClient(
            (_) => http.Response(jsonEncode({'summary': {}}), 200),
          ),
        );
        final r = await CollectionAnalyticsService.fetch('teqqles');
        expect(r.analytics, isNotNull);
        expect(r.analytics!.mostCoveredPlayerCount, isNull);
        // Empty 200 means analytics are still being computed.
        expect(r.retryable, isTrue);
      },
    );
  });

  group('CollectionAnalyticsService.fetch — Error', () {
    test('404 (no such user) gives up, not retryable', () async {
      HttpRetryClient.setTestClient(
        SyncMockClient((_) => http.Response('nope', 404)),
      );
      final r = await CollectionAnalyticsService.fetch('teqqles');
      expect(r.analytics, isNull);
      expect(r.retryable, isFalse);
    });

    test('5xx (still computing) is retryable', () async {
      HttpRetryClient.setTestClient(
        SyncMockClient((_) => http.Response('boom', 503)),
      );
      final r = await CollectionAnalyticsService.fetch('teqqles');
      expect(r.analytics, isNull);
      expect(r.retryable, isTrue);
    });

    test('invalid JSON on 200 gives up, not retryable', () async {
      HttpRetryClient.setTestClient(
        SyncMockClient((_) => http.Response('not json', 200)),
      );
      final r = await CollectionAnalyticsService.fetch('teqqles');
      expect(r.analytics, isNull);
      expect(r.retryable, isFalse);
    });

    test('non-map JSON on 200 gives up, not retryable', () async {
      HttpRetryClient.setTestClient(
        SyncMockClient((_) => http.Response('[1,2,3]', 200)),
      );
      final r = await CollectionAnalyticsService.fetch('teqqles');
      expect(r.analytics, isNull);
      expect(r.retryable, isFalse);
    });

    test('thrown client error is retryable (network/timeout)', () async {
      HttpRetryClient.setTestClient(
        SyncMockClient((_) {
          throw Exception('network down');
        }),
      );
      final r = await CollectionAnalyticsService.fetch('teqqles');
      expect(r.analytics, isNull);
      expect(r.retryable, isTrue);
    });
  });
}
