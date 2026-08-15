import 'dart:convert';

import 'package:how_many_mobile_meeple/api/http_retry_client.dart';
import 'package:how_many_mobile_meeple/app_common.dart';
import 'package:how_many_mobile_meeple/model/collection_analytics.dart';

/// Fetches per-collection analytics used to seed filter defaults.
///
/// Never throws: any failure (non-200, network error, malformed body) yields
/// null so callers can degrade silently.
class CollectionAnalyticsService {
  static Future<CollectionAnalytics?> fetch(String username) async {
    try {
      final url = Uri.parse(
          '${AppCommon.boardGameGeekProxyUrl}/collection/${Uri.encodeComponent(username)}/analytics');
      final response = await HttpRetryClient.getWithRetry(url);
      if (response.statusCode != 200) return null;
      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) return null;
      return CollectionAnalytics.fromJson(body);
    } catch (_) {
      return null;
    }
  }
}
