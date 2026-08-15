@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:how_many_mobile_meeple/model/collection_analytics.dart';

Map<String, dynamic> _fullBody() => {
      'summary': {
        'average_weight': 2.3,
        'median_rating': 7.42,
        'total_games': 113
      },
      'complexity_distribution': [
        {'label': 'light [0, 2.0)', 'count': 40},
        {'label': 'medium [2.5, 3.0)', 'count': 23},
      ],
      'playtime_distribution': [
        {'label': 'filler [0, 30)', 'count': 14},
        {'label': 'short [30, 60)', 'count': 32},
        {'label': 'medium [60, 90)', 'count': 26},
      ],
      'player_count_coverage': [
        {'player_count': 2, 'best_or_recommended': 82, 'supported': 103},
        {'player_count': 4, 'best_or_recommended': 99, 'supported': 109},
        {'player_count': 3, 'best_or_recommended': 95, 'supported': 108},
      ],
    };

void main() {
  group('CollectionAnalytics.fromJson — Right', () {
    test('parses the full sample body', () {
      final a = CollectionAnalytics.fromJson(_fullBody());
      expect(a.mostCoveredPlayerCount, 4);
      expect(a.averageWeight, 2.3);
      expect(a.dominantPlaytime!.min, 30);
      expect(a.dominantPlaytime!.max, 60);
    });
  });

  group('CollectionAnalytics.fromJson — Boundary', () {
    test('empty sections yield all-null fields', () {
      final a = CollectionAnalytics.fromJson({
        'summary': {},
        'complexity_distribution': [],
        'playtime_distribution': [],
        'player_count_coverage': [],
      });
      expect(a.mostCoveredPlayerCount, isNull);
      expect(a.averageWeight, isNull);
      expect(a.dominantPlaytime, isNull);
    });

    test('tie in best_or_recommended resolves to lowest player_count', () {
      final a = CollectionAnalytics.fromJson({
        'player_count_coverage': [
          {'player_count': 5, 'best_or_recommended': 50},
          {'player_count': 3, 'best_or_recommended': 50},
        ],
      });
      expect(a.mostCoveredPlayerCount, 3);
    });

    test('open-ended playtime bucket (120+) has null max', () {
      final a = CollectionAnalytics.fromJson({
        'playtime_distribution': [
          {'label': 'epic [120+)', 'count': 99},
          {'label': 'short [30, 60)', 'count': 1},
        ],
      });
      expect(a.dominantPlaytime!.min, 120);
      expect(a.dominantPlaytime!.max, isNull);
    });
  });

  group('CollectionAnalytics.fromJson — Inverse (weight fallback path)', () {
    test('uses complexity bucket midpoint when average_weight absent', () {
      final a = CollectionAnalytics.fromJson({
        'summary': {'total_games': 10},
        'complexity_distribution': [
          {'label': 'light [0, 2.0)', 'count': 5},
          {'label': 'medium [2.0, 3.0)', 'count': 40},
        ],
      });
      // Highest-count bucket is [2.0, 3.0) -> midpoint 2.5
      expect(a.averageWeight, 2.5);
    });
  });

  group('CollectionAnalytics.fromJson — Cross-check', () {
    test('mostCoveredPlayerCount matches an independent argmax', () {
      final body = _fullBody();
      final list = (body['player_count_coverage'] as List).cast<Map>();
      final expected = list.reduce((a, b) =>
          (b['best_or_recommended'] as int) > (a['best_or_recommended'] as int)
              ? b
              : a)['player_count'];
      final a = CollectionAnalytics.fromJson(body);
      expect(a.mostCoveredPlayerCount, expected);
    });

    test('averageWeight equals summary.average_weight verbatim', () {
      final a = CollectionAnalytics.fromJson(_fullBody());
      expect(
          a.averageWeight, (_fullBody()['summary'] as Map)['average_weight']);
    });
  });

  group('CollectionAnalytics.fromJson — Error', () {
    test('missing sections do not throw and yield nulls', () {
      final a = CollectionAnalytics.fromJson({});
      expect(a.mostCoveredPlayerCount, isNull);
      expect(a.averageWeight, isNull);
      expect(a.dominantPlaytime, isNull);
    });

    test('malformed playtime label yields null dominantPlaytime', () {
      final a = CollectionAnalytics.fromJson({
        'playtime_distribution': [
          {'label': 'weird', 'count': 5},
        ],
      });
      expect(a.dominantPlaytime, isNull);
    });

    test('non-numeric counts do not throw', () {
      final a = CollectionAnalytics.fromJson({
        'player_count_coverage': [
          {'player_count': 2, 'best_or_recommended': 'oops'},
        ],
      });
      expect(a.mostCoveredPlayerCount, isNull);
    });

    test('int average_weight is coerced to double', () {
      final a = CollectionAnalytics.fromJson({
        'summary': {'average_weight': 3}
      });
      expect(a.averageWeight, 3.0);
    });
  });

  group('CollectionAnalytics.fromJson — Performance', () {
    test('parses a large distribution in linear time', () {
      final big = List.generate(
          1000, (i) => {'player_count': i + 1, 'best_or_recommended': i});
      final sw = Stopwatch()..start();
      final a = CollectionAnalytics.fromJson({'player_count_coverage': big});
      sw.stop();
      expect(a.mostCoveredPlayerCount, 1000);
      expect(sw.elapsedMilliseconds, lessThan(200));
    });
  });
}
