@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:how_many_mobile_meeple/model/collection_analytics.dart';
import 'package:how_many_mobile_meeple/model/filter_seeder.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';

CollectionAnalytics _analytics({
  int? players = 4,
  double? weight = 2.3,
  PlaytimeRange? time = const PlaytimeRange(30, 60),
}) =>
    CollectionAnalytics(
      mostCoveredPlayerCount: players,
      averageWeight: weight,
      dominantPlaytime: time,
    );

void main() {
  group('FilterSeeder.seed — Right', () {
    test('seeds untouched filters, leaving them disabled', () {
      final s = Settings.defaultSettings();
      final changed = FilterSeeder.seed(_analytics(), s);

      expect(changed, isTrue);
      expect(s.setting(Settings.filterNumberOfPlayers.name).value, 4);
      expect(s.setting(Settings.filterMinimumTimeToPlay.name).value, 30);
      expect(s.setting(Settings.filterMaximumTimeToPlay.name).value, 60);
      expect(s.setting(Settings.filterComplexity.name).value, 2.3);
      // Position-only: nothing gets enabled.
      expect(s.setting(Settings.filterNumberOfPlayers.name).enabled, isFalse);
      expect(s.setting(Settings.filterComplexity.name).enabled, isFalse);
    });
  });

  group('FilterSeeder.seed — Boundary', () {
    test('clamps out-of-range player count to slider max', () {
      final s = Settings.defaultSettings();
      FilterSeeder.seed(_analytics(players: 12), s);
      expect(s.setting(Settings.filterNumberOfPlayers.name).value, 10);
    });

    test('null max leaves max time untouched', () {
      final s = Settings.defaultSettings();
      final before = s.setting(Settings.filterMaximumTimeToPlay.name).value;
      FilterSeeder.seed(_analytics(time: const PlaytimeRange(120, null)), s);
      expect(s.setting(Settings.filterMinimumTimeToPlay.name).value, 120);
      expect(s.setting(Settings.filterMaximumTimeToPlay.name).value, before);
    });
  });

  group('FilterSeeder.seed — Inverse (idempotent / stops after enable)', () {
    test('seeding twice while disabled is idempotent', () {
      final s = Settings.defaultSettings();
      FilterSeeder.seed(_analytics(), s);
      final second = FilterSeeder.seed(_analytics(), s);
      expect(second, isFalse); // nothing left to change
      expect(s.setting(Settings.filterNumberOfPlayers.name).value, 4);
    });

    test('an enabled (user-touched) filter is never overwritten', () {
      final s = Settings.defaultSettings();
      final players = s.setting(Settings.filterNumberOfPlayers.name);
      players.value = 2;
      players.enabled = true; // user made a selection
      FilterSeeder.seed(_analytics(players: 4), s);
      expect(players.value, 2);
    });
  });

  group('FilterSeeder.seed — Cross-check (per-filter independence)', () {
    test('seeds untouched siblings while skipping a user-set filter', () {
      final s = Settings.defaultSettings();
      final time = s.setting(Settings.filterMinimumTimeToPlay.name);
      time.value = 45;
      time.enabled = true;

      final changed = FilterSeeder.seed(_analytics(), s);

      expect(changed, isTrue);
      expect(time.value, 45); // user-set, untouched
      expect(s.setting(Settings.filterNumberOfPlayers.name).value, 4); // seeded
      expect(s.setting(Settings.filterComplexity.name).value, 2.3); // seeded
    });
  });

  group('FilterSeeder.seed — Error (null fields)', () {
    test('null field seeds nothing for that filter', () {
      final s = Settings.defaultSettings();
      final playersBefore =
          s.setting(Settings.filterNumberOfPlayers.name).value;
      FilterSeeder.seed(_analytics(players: null, time: null, weight: 2.3), s);
      expect(
          s.setting(Settings.filterNumberOfPlayers.name).value, playersBefore);
      expect(s.setting(Settings.filterComplexity.name).value, 2.3);
    });

    test('all-null analytics returns false and mutates nothing', () {
      final s = Settings.defaultSettings();
      final changed = FilterSeeder.seed(const CollectionAnalytics(), s);
      expect(changed, isFalse);
    });
  });
}
