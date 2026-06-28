import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:how_many_mobile_meeple/api/http_retry_client.dart';

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
        http_testing.MockClient((request) async {
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
        http_testing.MockClient((request) async {
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
        http_testing.MockClient((request) async {
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
        http_testing.MockClient((request) async {
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

    test('returns non-retryable error status immediately', () async {
      int callCount = 0;
      HttpRetryClient.setTestClient(
        http_testing.MockClient((request) async {
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
        http_testing.MockClient((request) async {
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
}
