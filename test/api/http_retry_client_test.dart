@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:how_many_mobile_meeple/api/http_retry_client.dart';
import '../helpers/sync_mock_client.dart';

void main() {
  setUp(() {
    HttpRetryClient.setDelayFunction((_) async {});
  });

  tearDown(() {
    HttpRetryClient.resetTestClient();
    HttpRetryClient.resetDelayFunction();
  });

  group('HttpRetryClient.getWithRetry', () {
    test('returns response immediately on 200', () async {
      int callCount = 0;
      HttpRetryClient.setTestClient(
        SyncMockClient((_) {
          callCount++;
          return http.Response('{"data": "ok"}', 200);
        }),
      );

      final response =
          await HttpRetryClient.getWithRetry(Uri.parse('http://test.com/api'));

      expect(response.statusCode, 200);
      expect(response.body, '{"data": "ok"}');
      expect(callCount, 1);
    });

    test('returns response immediately on 404', () async {
      int callCount = 0;
      HttpRetryClient.setTestClient(
        SyncMockClient((_) {
          callCount++;
          return http.Response('not found', 404);
        }),
      );

      final response =
          await HttpRetryClient.getWithRetry(Uri.parse('http://test.com/api'));

      expect(response.statusCode, 404);
      expect(callCount, 1);
    });

    test('retries on 202 then succeeds on 200', () async {
      int callCount = 0;
      HttpRetryClient.setTestClient(
        SyncMockClient((_) {
          callCount++;
          if (callCount < 3) {
            return http.Response('processing', 202);
          }
          return http.Response('{"data": "ok"}', 200);
        }),
      );

      final response =
          await HttpRetryClient.getWithRetry(Uri.parse('http://test.com/api'));

      expect(response.statusCode, 200);
      expect(callCount, 3);
    });

    test('passes headers to the request', () async {
      String? capturedHeader;
      HttpRetryClient.setTestClient(
        SyncMockClient((request) {
          capturedHeader = request.headers['X-Custom'];
          return http.Response('ok', 200);
        }),
      );

      await HttpRetryClient.getWithRetry(
        Uri.parse('http://test.com/api'),
        headers: {'X-Custom': 'test-value'},
      );

      expect(capturedHeader, 'test-value');
    });

    test('sends Accept-Encoding gzip header on all requests', () async {
      Map<String, String>? capturedHeaders;
      HttpRetryClient.setTestClient(
        SyncMockClient((request) {
          capturedHeaders = request.headers;
          return http.Response('ok', 200);
        }),
      );

      await HttpRetryClient.getWithRetry(Uri.parse('http://test.com/api'));

      expect(capturedHeaders!['Accept-Encoding'], 'gzip');
    });

    test('caller headers override Accept-Encoding if specified', () async {
      Map<String, String>? capturedHeaders;
      HttpRetryClient.setTestClient(
        SyncMockClient((request) {
          capturedHeaders = request.headers;
          return http.Response('ok', 200);
        }),
      );

      await HttpRetryClient.getWithRetry(
        Uri.parse('http://test.com/api'),
        headers: {'Accept-Encoding': 'br'},
      );

      expect(capturedHeaders!['Accept-Encoding'], 'br');
    });

    test('does not send Accept-Encoding gzip for cors-proxy requests',
        () async {
      Map<String, String>? capturedHeaders;
      HttpRetryClient.setTestClient(
        SyncMockClient((request) {
          capturedHeaders = request.headers;
          return http.Response('ok', 200);
        }),
      );

      await HttpRetryClient.getWithRetry(
        Uri.parse('http://test.com/cors-proxy/_abc123'),
      );

      expect(capturedHeaders!.containsKey('Accept-Encoding'), isFalse);
    });

    test('returns non-retryable error status immediately', () async {
      int callCount = 0;
      HttpRetryClient.setTestClient(
        SyncMockClient((_) {
          callCount++;
          return http.Response('server error', 500);
        }),
      );

      final response =
          await HttpRetryClient.getWithRetry(Uri.parse('http://test.com/api'));

      expect(response.statusCode, 500);
      expect(callCount, 1);
    });

    test('respects custom retryableStatuses', () async {
      int callCount = 0;
      HttpRetryClient.setTestClient(
        SyncMockClient((_) {
          callCount++;
          if (callCount < 3) {
            return http.Response('rate limited', 429);
          }
          return http.Response('ok', 200);
        }),
      );

      final response = await HttpRetryClient.getWithRetry(
        Uri.parse('http://test.com/api'),
        retryableStatuses: {202, 429},
      );

      expect(response.statusCode, 200);
      expect(callCount, 3);
    });
  });

  group('HttpRetryClient backoff timing', () {
    test('calls delay with exponential backoff durations', () async {
      final delays = <Duration>[];
      HttpRetryClient.setDelayFunction((d) async => delays.add(d));

      int callCount = 0;
      HttpRetryClient.setTestClient(
        SyncMockClient((_) {
          callCount++;
          if (callCount < 4) {
            return http.Response('processing', 202);
          }
          return http.Response('ok', 200);
        }),
      );

      await HttpRetryClient.getWithRetry(Uri.parse('http://test.com/api'));

      expect(delays.length, 3);
      expect(delays[0], const Duration(seconds: 2));
      expect(delays[1], const Duration(seconds: 4));
      expect(delays[2], const Duration(seconds: 8));
    });

    test('backoff caps at 30 seconds', () async {
      final delays = <Duration>[];
      HttpRetryClient.setDelayFunction((d) async => delays.add(d));

      int callCount = 0;
      HttpRetryClient.setTestClient(
        SyncMockClient((_) {
          callCount++;
          if (callCount < 7) {
            return http.Response('processing', 202);
          }
          return http.Response('ok', 200);
        }),
      );

      await HttpRetryClient.getWithRetry(Uri.parse('http://test.com/api'));

      // 2, 4, 8, 16, 30, 30
      expect(delays.last, const Duration(seconds: 30));
    });
  });

  group('HttpRetryClient error conditions', () {
    test('propagates network exception from client', () async {
      HttpRetryClient.setTestClient(
        SyncMockClient((_) {
          throw http.ClientException('Connection refused');
        }),
      );

      expect(
        () => HttpRetryClient.getWithRetry(Uri.parse('http://test.com/api')),
        throwsA(isA<http.ClientException>()),
      );
    });

    test(
        'does not retry non-retryable status even if server returns it repeatedly',
        () async {
      int callCount = 0;
      HttpRetryClient.setTestClient(
        SyncMockClient((_) {
          callCount++;
          return http.Response('bad request', 400);
        }),
      );

      final response = await HttpRetryClient.getWithRetry(
        Uri.parse('http://test.com/api'),
      );

      expect(response.statusCode, 400);
      expect(callCount, 1);
    });
  });
}
