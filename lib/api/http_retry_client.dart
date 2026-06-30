import 'package:http/http.dart' as http;

typedef DelayFunction = Future<void> Function(Duration duration);

class HttpRetryClient {
  static const int _initialBackoffSeconds = 2;
  static const int _maxBackoffSeconds = 30;
  static const Duration _retryTimeout = Duration(seconds: 600);

  static http.Client? _testClient;
  static DelayFunction _delayFn = (d) => Future.delayed(d);

  static void setTestClient(http.Client client) {
    _testClient = client;
  }

  static void resetTestClient() {
    _testClient = null;
  }

  static void setDelayFunction(DelayFunction fn) {
    _delayFn = fn;
  }

  static void resetDelayFunction() {
    _delayFn = (d) => Future.delayed(d);
  }

  static Future<http.Response> getWithRetry(
    Uri url, {
    Map<String, String>? headers,
    Set<int> retryableStatuses = const {202},
  }) async {
    final deadline = DateTime.now().add(_retryTimeout);
    int backoff = _initialBackoffSeconds;

    final isCorsProxy = url.path.contains('/cors-proxy/');
    final mergedHeaders = {
      if (!isCorsProxy) 'Accept-Encoding': 'gzip',
      ...?headers,
    };

    while (true) {
      final client = _testClient ?? http.Client();
      try {
        final response = await client.get(url, headers: mergedHeaders);

        if (!retryableStatuses.contains(response.statusCode) ||
            DateTime.now().isAfter(deadline)) {
          return response;
        }

        await _delayFn(Duration(seconds: backoff));
        backoff = (backoff * 2).clamp(0, _maxBackoffSeconds);
      } finally {
        if (_testClient == null) {
          client.close();
        }
      }
    }
  }
}
