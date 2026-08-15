import 'package:how_many_mobile_meeple/model/collection_analytics.dart';
import 'package:how_many_mobile_meeple/model/setting.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';

/// Seeds untouched filter sliders from a collection's analytics sweet spot.
/// Position-only: writes a value only for filters the user has not touched and
/// leaves `enabled` false, so it never applies a filter. Returns true on change.
class FilterSeeder {
  static const int _minPlayers = 1;
  static const int _maxPlayers = 10;
  static const int _minTime = 15;
  static const int _maxTime = 300;
  static const double _minWeight = 0.5;
  static const double _maxWeight = 5.0;

  static bool seed(CollectionAnalytics analytics, Settings settings) {
    var changed = false;

    changed |= _seedInt(
      settings.setting(Settings.filterNumberOfPlayers.name),
      analytics.mostCoveredPlayerCount,
      _minPlayers,
      _maxPlayers,
    );

    final time = analytics.dominantPlaytime;
    if (time != null) {
      changed |= _seedTimeRange(settings, time);
    }

    changed |= _seedDouble(
      settings.setting(Settings.filterComplexity.name),
      analytics.averageWeight,
      _minWeight,
      _maxWeight,
    );

    return changed;
  }

  /// Seeds the time range as one operation: fix the effective max first, then
  /// clamp min below it, so the two sliders can never invert.
  static bool _seedTimeRange(Settings settings, PlaytimeRange time) {
    var changed = false;
    final minSetting = settings.setting(Settings.filterMinimumTimeToPlay.name);
    final maxSetting = settings.setting(Settings.filterMaximumTimeToPlay.name);

    // Determine effective max: seed from bucket if untouched, else use current.
    int effectiveMax;
    if (!maxSetting.enabled) {
      // Untouched: seed from bucket (use slider max for open-ended).
      final bucketMax = time.max ?? _maxTime;
      final clampedMax = bucketMax.clamp(_minTime, _maxTime).toInt();
      if (maxSetting.value != clampedMax) {
        maxSetting.value = clampedMax;
        changed = true;
      }
      effectiveMax = clampedMax;
    } else {
      // User-set: leave it, use as constraint.
      effectiveMax = maxSetting.value as int;
    }

    // Seed min, clamped to never exceed effective max.
    if (!minSetting.enabled) {
      final clampedMin = time.min.clamp(_minTime, effectiveMax).toInt();
      if (minSetting.value != clampedMin) {
        minSetting.value = clampedMin;
        changed = true;
      }
    }

    return changed;
  }

  /// Writes [value] (clamped) into [setting] only if the user has not touched
  /// it and the value actually differs. Keeps `enabled` false.
  static bool _seedInt(Setting setting, int? value, int lo, int hi) {
    if (value == null || setting.enabled) return false;
    final clamped = value.clamp(lo, hi).toInt();
    if (setting.value == clamped) return false;
    setting.value = clamped;
    return true;
  }

  static bool _seedDouble(
      Setting setting, double? value, double lo, double hi) {
    if (value == null || setting.enabled) return false;
    final clamped = value.clamp(lo, hi).toDouble();
    if (setting.value == clamped) return false;
    setting.value = clamped;
    return true;
  }
}
