@Tags(['unit'])
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:how_many_mobile_meeple/api/prefetch_service.dart';
import 'package:how_many_mobile_meeple/model/item.dart';
import '../helpers/sync_mock_client.dart';

void main() {
  tearDown(() {
    PrefetchService.resetTestClient();
  });

  group('PrefetchService.warmCache', () {
    test('sends POST request with item details', () async {
      Map<String, dynamic>? capturedBody;
      PrefetchService.setTestClient(
        SyncMockClient((request) {
          capturedBody = json.decode((request as http.Request).body);
          return http.Response('ok', 200);
        }),
      );

      final item = Item('testuser', itemType: ItemType.collection);
      await PrefetchService.warmCache(item);

      expect(capturedBody, isNotNull);
      expect(capturedBody!['source_type'], 'collection');
      expect(capturedBody!['source_id'], 'testuser');
    });

    test('skips duplicate warm requests', () async {
      int callCount = 0;
      PrefetchService.setTestClient(
        SyncMockClient((_) {
          callCount++;
          return http.Response('ok', 200);
        }),
      );

      final item = Item('testuser', itemType: ItemType.collection);
      await PrefetchService.warmCache(item);
      await PrefetchService.warmCache(item);

      expect(callCount, 1);
    });

    test('allows retry after failure', () async {
      int callCount = 0;
      PrefetchService.setTestClient(
        SyncMockClient((_) {
          callCount++;
          if (callCount == 1) throw http.ClientException('network error');
          return http.Response('ok', 200);
        }),
      );

      final item = Item('testuser', itemType: ItemType.collection);
      await PrefetchService.warmCache(item);
      await PrefetchService.warmCache(item);

      expect(callCount, 2);
    });

    test('sends Content-Type header', () async {
      String? contentType;
      PrefetchService.setTestClient(
        SyncMockClient((request) {
          contentType = request.headers['content-type'];
          return http.Response('ok', 200);
        }),
      );

      await PrefetchService.warmCache(
        Item('12345', itemType: ItemType.geekList),
      );

      expect(contentType, contains('application/json'));
    });
  });
}
