import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

typedef SyncHandler = http.Response Function(http.BaseRequest request);

/// A test HTTP client that returns responses synchronously via Future.value().
///
/// Bypasses BaseClient._sendUnstreamed() and stream processing entirely
/// to avoid microtask scheduling issues in Flutter's test zone.
class SyncMockClient implements http.Client {
  final SyncHandler _handler;

  SyncMockClient(this._handler);

  SyncMockClient.respond(int statusCode, String body)
      : _handler = ((_) => http.Response(body, statusCode));

  http.Response _call(String method, Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) {
    final request = http.Request(method, url);
    if (headers != null) request.headers.addAll(headers);
    if (body != null) {
      if (body is String) {
        request.body = body;
      } else if (body is List<int>) {
        request.bodyBytes = Uint8List.fromList(body);
      } else if (body is Map) {
        request.bodyFields = body.cast<String, String>();
      }
    }
    if (encoding != null) request.encoding = encoding;
    return _handler(request);
  }

  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) =>
      Future.value(_call('GET', url, headers: headers));

  @override
  Future<http.Response> post(Uri url,
          {Map<String, String>? headers, Object? body, Encoding? encoding}) =>
      Future.value(
          _call('POST', url, headers: headers, body: body, encoding: encoding));

  @override
  Future<http.Response> put(Uri url,
          {Map<String, String>? headers, Object? body, Encoding? encoding}) =>
      Future.value(
          _call('PUT', url, headers: headers, body: body, encoding: encoding));

  @override
  Future<http.Response> patch(Uri url,
          {Map<String, String>? headers, Object? body, Encoding? encoding}) =>
      Future.value(_call('PATCH', url,
          headers: headers, body: body, encoding: encoding));

  @override
  Future<http.Response> delete(Uri url,
          {Map<String, String>? headers, Object? body, Encoding? encoding}) =>
      Future.value(_call('DELETE', url,
          headers: headers, body: body, encoding: encoding));

  @override
  Future<http.Response> head(Uri url, {Map<String, String>? headers}) =>
      Future.value(_call('HEAD', url, headers: headers));

  @override
  Future<String> read(Uri url, {Map<String, String>? headers}) async =>
      (await get(url, headers: headers)).body;

  @override
  Future<Uint8List> readBytes(Uri url, {Map<String, String>? headers}) async =>
      (await get(url, headers: headers)).bodyBytes;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    final response = _handler(request);
    final bytes = utf8.encode(response.body);
    return Future.value(http.StreamedResponse(
      Stream.value(bytes),
      response.statusCode,
      headers: response.headers,
      reasonPhrase: response.reasonPhrase,
      contentLength: bytes.length,
      request: request,
    ));
  }

  @override
  void close() {}
}
