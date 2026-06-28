import 'dart:convert';
import 'package:how_many_mobile_meeple/api/http_retry_client.dart';
import 'package:how_many_mobile_meeple/app_common.dart';
import 'package:how_many_mobile_meeple/model/play_data.dart';

class _CachedPlays {
  final Map<int, PlayData> plays;
  final int timestamp;

  _CachedPlays(this.plays, this.timestamp);

  bool get isStale =>
      DateTime.now().millisecondsSinceEpoch - timestamp > _cacheDurationMs;

  static const int _cacheDurationMs = 30 * 60 * 1000;
}

class PlaysService {
  static final Map<String, _CachedPlays> _cache = {};

  static void clearCache() {
    _cache.clear();
  }

  static Future<Map<int, PlayData>> fetchPlays(String username) async {
    final cached = _cache[username];
    if (cached != null && !cached.isStale) {
      return cached.plays;
    }

    final url = Uri.parse('${AppCommon.boardGameGeekProxyUrl}/plays/$username');
    final response = await HttpRetryClient.getWithRetry(url);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      final Map<int, PlayData> plays = {};
      for (final json in jsonList) {
        final playData = PlayData.fromJson(json);
        plays[playData.gameId] = playData;
      }
      _cache[username] =
          _CachedPlays(plays, DateTime.now().millisecondsSinceEpoch);
      return plays;
    }

    if (response.statusCode == 404) {
      return {};
    }

    throw Exception(
        'Failed to load plays for $username (${response.statusCode})');
  }
}
