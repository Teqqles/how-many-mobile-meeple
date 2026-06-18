import 'package:shared_preferences/shared_preferences.dart';
import 'tour_tip.dart';

class TourTipStorage {
  static const String _prefix = 'tour_tip_seen_';
  static const String _globalDisableKey = 'tour_tips_disabled';

  final SharedPreferences _prefs;

  TourTipStorage(this._prefs);

  static Future<TourTipStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return TourTipStorage(prefs);
  }

  bool isSeen(String tipId) => _prefs.getBool('$_prefix$tipId') ?? false;

  Future<void> markSeen(String tipId) async {
    await _prefs.setBool('$_prefix$tipId', true);
  }

  bool get isGloballyDisabled => _prefs.getBool(_globalDisableKey) ?? false;

  Future<void> setGloballyDisabled(bool disabled) async {
    await _prefs.setBool(_globalDisableKey, disabled);
  }

  List<TourTip> unseenTips(List<TourTip> tips) =>
      tips.where((t) => !isSeen(t.id)).toList();

  Future<void> resetAll() async {
    final keys = _prefs.getKeys().where((k) => k.startsWith(_prefix));
    for (final key in keys.toList()) {
      await _prefs.remove(key);
    }
  }
}
