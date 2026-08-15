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

    test('open-ended bucket with both time settings untouched seeds max to 300',
        () {
      final s = Settings.defaultSettings();
      FilterSeeder.seed(_analytics(time: const PlaytimeRange(120, null)), s);
      final min = s.setting(Settings.filterMinimumTimeToPlay.name).value;
      final max = s.setting(Settings.filterMaximumTimeToPlay.name).value;
      expect(min, 120);
      expect(max, 300); // open-ended → slider max
      expect(min <= max, isTrue, reason: 'min must not exceed max');
    });

    test('open-ended bucket with max user-set clamps seeded min to that max',
        () {
      final s = Settings.defaultSettings();
      final maxSetting = s.setting(Settings.filterMaximumTimeToPlay.name);
      maxSetting.value = 90;
      maxSetting.enabled = true; // user-set
      FilterSeeder.seed(_analytics(time: const PlaytimeRange(120, null)), s);
      final min = s.setting(Settings.filterMinimumTimeToPlay.name).value;
      final max = maxSetting.value;
      expect(max, 90); // user-set, unchanged
      expect(min, 90); // clamped to max
      expect(min <= max, isTrue, reason: 'min must not exceed max');
    });

    test('closed bucket min exceeding user-set max is clamped', () {
      final s = Settings.defaultSettings();
      final maxSetting = s.setting(Settings.filterMaximumTimeToPlay.name);
      maxSetting.value = 60;
      maxSetting.enabled = true; // user-set
      FilterSeeder.seed(_analytics(time: const PlaytimeRange(90, 120)), s);
      final min = s.setting(Settings.filterMinimumTimeToPlay.name).value;
      final max = maxSetting.value;
      expect(max, 60); // user-set, unchanged
      expect(min, 60); // clamped to max
      expect(min <= max, isTrue, reason: 'min must not exceed max');
    });

    test('complexity seeds to slider floor when analytics is below it', () {
      final s = Settings.defaultSettings();
      FilterSeeder.seed(_analytics(weight: 0.3), s);
      expect(s.setting(Settings.filterComplexity.name).value, 0.5);
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
