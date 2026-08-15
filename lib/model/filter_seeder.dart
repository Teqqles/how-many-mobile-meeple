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
  static const double _minWeight = 0.0;
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
      changed |= _seedInt(
        settings.setting(Settings.filterMinimumTimeToPlay.name),
        time.min,
        _minTime,
        _maxTime,
      );
      changed |= _seedInt(
        settings.setting(Settings.filterMaximumTimeToPlay.name),
        time.max,
        _minTime,
        _maxTime,
      );
    }

    changed |= _seedDouble(
      settings.setting(Settings.filterComplexity.name),
      analytics.averageWeight,
      _minWeight,
      _maxWeight,
    );

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
