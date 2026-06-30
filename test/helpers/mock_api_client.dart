import 'dart:convert';
import 'package:http/http.dart' as http;
import 'sync_mock_client.dart';

SyncMockClient mockApiClient({
  List<Map<String, dynamic>> plays = const [],
  bool playsComplete = true,
  int retryAfterSeconds = 0,
  List<Map<String, dynamic>> collection = const [],
  void Function(http.BaseRequest)? onRequest,
}) {
  return SyncMockClient((request) {
    onRequest?.call(request);
    if (request.url.path.startsWith('/plays/')) {
      final meta = <String, dynamic>{'complete': playsComplete};
      if (!playsComplete && retryAfterSeconds > 0) {
        meta['retry_after_seconds'] = retryAfterSeconds;
      }
      return http.Response(jsonEncode({'plays': plays, 'meta': meta}), 200);
    }
    if (request.url.path.startsWith('/collection/') ||
        request.url.path.startsWith('/hot')) {
      return http.Response(jsonEncode(collection), 200);
    }
    return http.Response('Not found', 404);
  });
}
