import 'dart:convert';

import 'package:how_many_mobile_meeple/api/http_retry_client.dart';
import 'package:how_many_mobile_meeple/app_common.dart';
import 'package:how_many_mobile_meeple/model/collection_analytics.dart';

/// Outcome of an analytics fetch. [retryable] is true when the endpoint is
/// transiently not-ready (202, empty 200, 5xx, network error); false when the
/// result is final (ready data, 404 no-such-user, or a malformed body).
class AnalyticsFetchResult {
  final CollectionAnalytics? analytics;
  final bool retryable;

  const AnalyticsFetchResult({this.analytics, this.retryable = false});

  static const notReady = AnalyticsFetchResult(retryable: true);
  static const givenUp = AnalyticsFetchResult(retryable: false);
}

/// Fetches per-collection analytics used to seed filter defaults. Never throws.
class CollectionAnalyticsService {
  static Future<AnalyticsFetchResult> fetch(String username) async {
    try {
      final url = Uri.parse(
        '${AppCommon.boardGameGeekProxyUrl}/collection/${Uri.encodeComponent(username)}/analytics',
      );
      final response = await HttpRetryClient.getWithRetry(url);
      final status = response.statusCode;
      if (status == 404) return AnalyticsFetchResult.givenUp; // no such user
      if (status != 200) return AnalyticsFetchResult.notReady; // 202, 5xx...

      final dynamic body;
      try {
        body = jsonDecode(response.body);
      } catch (_) {
        return AnalyticsFetchResult.givenUp; // malformed 200, not worth retry
      }
      if (body is! Map<String, dynamic>) return AnalyticsFetchResult.givenUp;

      final analytics = CollectionAnalytics.fromJson(body);
      // An empty 200 means the analytics are still being computed.
      return AnalyticsFetchResult(
        analytics: analytics,
        retryable: !analytics.hasData,
      );
    } catch (_) {
      return AnalyticsFetchResult.notReady; // network / timeout
    }
  }
}
