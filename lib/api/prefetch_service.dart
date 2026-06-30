import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:how_many_mobile_meeple/app_common.dart';
import 'package:how_many_mobile_meeple/model/item.dart';

class PrefetchService {
  static final Set<String> _warmed = {};
  static http.Client? _testClient;

  static void setTestClient(http.Client client) => _testClient = client;
  static void resetTestClient() {
    _testClient = null;
    _warmed.clear();
  }

  static Future<void> warmCache(Item item) async {
    final key = '${item.itemType.name}:${item.name}';
    if (!_warmed.add(key)) return;
    final client = _testClient ?? http.Client();
    try {
      await client.post(
        Uri.parse('${AppCommon.boardGameGeekProxyUrl}/prefetch'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'source_type': item.itemType.name,
          'source_id': item.name,
        }),
      );
    } catch (_) {
      _warmed.remove(key);
    } finally {
      if (_testClient == null) client.close();
    }
  }
}
