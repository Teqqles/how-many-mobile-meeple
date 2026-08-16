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
      'top_mechanics': [
        {'name': 'Hand Management', 'count': 43},
        {'name': 'Set Collection', 'count': 39},
        {'name': 'Dice Rolling', 'count': 38},
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

  group('CollectionAnalytics.topMechanics', () {
    test('parses top_mechanics as name/count pairs in order', () {
      final a = CollectionAnalytics.fromJson(_fullBody());
      expect(a.topMechanics.map((m) => m.name).toList(),
          ['Hand Management', 'Set Collection', 'Dice Rolling']);
      expect(a.topMechanics.first.count, 43);
    });

    test('sorts descending by count when the source is unsorted', () {
      final a = CollectionAnalytics.fromJson({
        'top_mechanics': [
          {'name': 'Low', 'count': 5},
          {'name': 'High', 'count': 50},
          {'name': 'Mid', 'count': 20},
        ],
      });
      expect(
          a.topMechanics.map((m) => m.name).toList(), ['High', 'Mid', 'Low']);
    });

    test('drops malformed entries without throwing', () {
      final a = CollectionAnalytics.fromJson({
        'top_mechanics': [
          {'name': 'Good', 'count': 10},
          {'name': 'NoCount'},
          {'count': 3},
          {'name': 42, 'count': 3},
          {'name': 'BadCount', 'count': 'oops'},
          'not a map',
        ],
      });
      expect(a.topMechanics.length, 1);
      expect(a.topMechanics.single.name, 'Good');
    });

    test('missing or non-list top_mechanics yields an empty list', () {
      expect(CollectionAnalytics.fromJson({}).topMechanics, isEmpty);
      expect(
          CollectionAnalytics.fromJson({'top_mechanics': 'nope'}).topMechanics,
          isEmpty);
    });
  });

  group('CollectionAnalytics raw distributions', () {
    test('parses player_count_coverage sorted ascending by player count', () {
      final a = CollectionAnalytics.fromJson(_fullBody());
      expect(
          a.playerCountCoverage.map((c) => c.playerCount).toList(), [2, 3, 4]);
      final three = a.playerCountCoverage.firstWhere((c) => c.playerCount == 3);
      expect(three.supported, 108);
      expect(three.bestOrRecommended, 95);
    });

    test('drops player coverage entries missing any field', () {
      final a = CollectionAnalytics.fromJson({
        'player_count_coverage': [
          {'player_count': 2, 'best_or_recommended': 82, 'supported': 103},
          {'player_count': 3, 'best_or_recommended': 95},
          {'best_or_recommended': 1, 'supported': 1},
          'nope',
        ],
      });
      expect(a.playerCountCoverage.length, 1);
      expect(a.playerCountCoverage.single.playerCount, 2);
    });

    test('parses complexity buckets with name and float range', () {
      final a = CollectionAnalytics.fromJson(_fullBody());
      expect(a.complexityDistribution.map((b) => b.name).toList(),
          ['light', 'medium']);
      final light = a.complexityDistribution.first;
      expect(light.min, 0);
      expect(light.max, 2.0);
      expect(light.count, 40);
    });

    test('parses playtime buckets with name and int range', () {
      final a = CollectionAnalytics.fromJson(_fullBody());
      expect(a.playtimeDistribution.map((b) => b.name).toList(),
          ['filler', 'short', 'medium']);
      final short = a.playtimeDistribution[1];
      expect(short.min, 30);
      expect(short.max, 60);
      expect(short.count, 32);
    });

    test('open-ended bucket has null max', () {
      final a = CollectionAnalytics.fromJson({
        'complexity_distribution': [
          {'label': 'heavy [4.0+)', 'count': 2},
        ],
        'playtime_distribution': [
          {'label': 'epic [120+)', 'count': 20},
        ],
      });
      expect(a.complexityDistribution.single.max, isNull);
      expect(a.playtimeDistribution.single.max, isNull);
    });

    test('drops buckets with malformed labels', () {
      final a = CollectionAnalytics.fromJson({
        'complexity_distribution': [
          {'label': 'light [0, 2.0)', 'count': 40},
          {'label': 'weird', 'count': 5},
          {'count': 3},
          {'label': 'nocount [0, 1.0)'},
        ],
      });
      expect(a.complexityDistribution.length, 1);
      expect(a.complexityDistribution.single.name, 'light');
    });

    test('missing or non-list sections yield empty distributions', () {
      final a = CollectionAnalytics.fromJson({});
      expect(a.playerCountCoverage, isEmpty);
      expect(a.complexityDistribution, isEmpty);
      expect(a.playtimeDistribution, isEmpty);
    });

    test('DistributionBucket.contains respects half-open range', () {
      const b = DistributionBucket(name: 'x', min: 2.0, max: 2.5, count: 1);
      expect(b.contains(2.0), isTrue);
      expect(b.contains(2.49), isTrue);
      expect(b.contains(2.5), isFalse);
      expect(b.contains(1.99), isFalse);
    });

    test('DistributionBucket.contains treats null max as open-ended', () {
      const b = DistributionBucket(name: 'x', min: 120, max: null, count: 1);
      expect(b.contains(120), isTrue);
      expect(b.contains(9999), isTrue);
      expect(b.contains(119), isFalse);
    });

    test('DistributionBucket.overlaps a selected range', () {
      const b = DistributionBucket(name: 'x', min: 30, max: 60, count: 1);
      expect(b.overlaps(0, 45), isTrue); // partial low overlap
      expect(b.overlaps(45, 90), isTrue); // partial high overlap
      expect(b.overlaps(30, 59), isTrue); // fully inside
      expect(b.overlaps(0, 29), isFalse); // ends before bucket
      expect(b.overlaps(60, 90), isFalse); // starts at exclusive top
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

    test('malformed complexity label (multiple dots) yields null averageWeight',
        () {
      final a = CollectionAnalytics.fromJson({
        'complexity_distribution': [
          {'label': 'bad [1.2.3, 4.5)', 'count': 10}
        ],
      });
      expect(a.averageWeight, isNull);
    });
  });

  group('CollectionAnalytics.hasData', () {
    test('true when any field is usable', () {
      expect(CollectionAnalytics.fromJson(_fullBody()).hasData, isTrue);
      expect(
          CollectionAnalytics.fromJson({
            'player_count_coverage': [
              {'player_count': 4, 'best_or_recommended': 99}
            ]
          }).hasData,
          isTrue);
    });

    test('true when only top_mechanics is present', () {
      final a = CollectionAnalytics.fromJson({
        'top_mechanics': [
          {'name': 'Hand Management', 'count': 43}
        ]
      });
      expect(a.hasData, isTrue);
    });

    test('false when all sections are empty (not-ready response)', () {
      final a = CollectionAnalytics.fromJson({
        'summary': {},
        'complexity_distribution': [],
        'playtime_distribution': [],
        'player_count_coverage': [],
      });
      expect(a.hasData, isFalse);
    });

    test('false for an empty body', () {
      expect(CollectionAnalytics.fromJson({}).hasData, isFalse);
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
      expect(sw.elapsedMilliseconds, lessThan(2000));
    });
  });
}
