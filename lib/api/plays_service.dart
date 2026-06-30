import 'dart:convert';
import 'package:how_many_mobile_meeple/api/http_retry_client.dart';
import 'package:how_many_mobile_meeple/app_common.dart';
import 'package:how_many_mobile_meeple/model/play_data.dart';

class PlaysResult {
  final Map<int, PlayData> plays;
  final bool complete;
  final int retryAfterSeconds;

  PlaysResult({
    required this.plays,
    required this.complete,
    this.retryAfterSeconds = 0,
  });
}

class _CachedPlays {
  final PlaysResult result;
  final int timestamp;

  _CachedPlays(this.result, this.timestamp);

  bool get isStale =>
      DateTime.now().millisecondsSinceEpoch - timestamp > _cacheDurationMs;

  static const int _cacheDurationMs = 30 * 60 * 1000;
}

class PlaysService {
  static final Map<String, _CachedPlays> _cache = {};
  static final Map<String, Future<PlaysResult>> _inFlight = {};

  static void clearCache() {
    _cache.clear();
    _inFlight.clear();
  }

  static Future<PlaysResult> fetchPlays(String username) {
    final cached = _cache[username];
    if (cached != null && !cached.isStale && cached.result.complete) {
      return Future.value(cached.result);
    }
    return _inFlight[username] ??= _doFetch(username);
  }

  static Future<PlaysResult> _doFetch(String username) async {
    try {
      final url =
          Uri.parse('${AppCommon.boardGameGeekProxyUrl}/plays/$username');
      final response = await HttpRetryClient.getWithRetry(
        url,
        headers: {'Bgg-Plays-Meta': 'true'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        final List<dynamic> playsList = json['plays'];
        final Map<String, dynamic> meta = json['meta'];

        final Map<int, PlayData> plays = {};
        for (final item in playsList) {
          final playData = PlayData.fromJson(item);
          plays[playData.gameId] = playData;
        }

        final bool complete = meta['complete'] as bool;
        final int retryAfter = (meta['retry_after_seconds'] as int?) ?? 0;

        final result = PlaysResult(
          plays: plays,
          complete: complete,
          retryAfterSeconds: retryAfter,
        );
        _cache[username] =
            _CachedPlays(result, DateTime.now().millisecondsSinceEpoch);
        return result;
      }

      if (response.statusCode == 404) {
        return PlaysResult(plays: {}, complete: true);
      }

      throw Exception(
          'Failed to load plays for $username (${response.statusCode})');
    } finally {
      _inFlight.remove(username);
    }
  }
}
