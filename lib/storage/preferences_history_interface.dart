import 'package:how_many_mobile_meeple/model/app_preferences.dart';

/// Abstract interface for preferences history storage
abstract class PreferencesHistoryInterface {
  Future<void> storePreference(AppPreferences preferences);
  Future<AppPreferences> loadPreference(int preferenceId);
  Future<bool> deletePreference(String preferenceId);
  Future<List<AppPreferences>> loadAllPreferences();
}
