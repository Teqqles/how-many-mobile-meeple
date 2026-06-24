import 'package:flutter_test/flutter_test.dart';
import 'package:how_many_mobile_meeple/model/app_preferences.dart';
import 'package:how_many_mobile_meeple/model/items.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';
import 'package:how_many_mobile_meeple/storage/preferences_history_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockPreferencesHistory implements PreferencesHistoryInterface {
  int loadAllCallCount = 0;
  List<AppPreferences> _preferences = [];

  void setPreferences(List<AppPreferences> prefs) {
    _preferences = prefs;
  }

  @override
  Future<List<AppPreferences>> loadAllPreferences() async {
    loadAllCallCount++;
    return List.from(_preferences);
  }

  @override
  Future<void> storePreference(AppPreferences preferences) async {
    _preferences.add(preferences);
  }

  @override
  Future<AppPreferences> loadPreference(int preferenceId) async {
    return _preferences.firstWhere((p) => p.id == preferenceId.toString());
  }

  @override
  Future<bool> deletePreference(String preferenceId) async {
    _preferences.removeWhere((p) => p.id == preferenceId);
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppModel.getSavedPreferences', () {
    test('loads from history on first call', () async {
      final mock = MockPreferencesHistory();
      mock.setPreferences([
        AppPreferences('1', 'Test', Items([]), Settings.defaultSettings()),
      ]);
      final model = AppModel(preferencesHistory: mock);

      final result = await model.getSavedPreferences();

      expect(result.length, 1);
      expect(result.first.title, 'Test');
      expect(mock.loadAllCallCount, 1);
    });

    test('returns cached results on subsequent calls', () async {
      final mock = MockPreferencesHistory();
      mock.setPreferences([
        AppPreferences('1', 'Test', Items([]), Settings.defaultSettings()),
      ]);
      final model = AppModel(preferencesHistory: mock);

      await model.getSavedPreferences();
      await model.getSavedPreferences();
      await model.getSavedPreferences();

      expect(mock.loadAllCallCount, 1);
    });

    test('reloads from history after invalidatePreferencesCache', () async {
      final mock = MockPreferencesHistory();
      mock.setPreferences([
        AppPreferences('1', 'First', Items([]), Settings.defaultSettings()),
      ]);
      final model = AppModel(preferencesHistory: mock);

      final first = await model.getSavedPreferences();
      expect(first.length, 1);
      expect(mock.loadAllCallCount, 1);

      mock.setPreferences([
        AppPreferences('1', 'First', Items([]), Settings.defaultSettings()),
        AppPreferences('2', 'Second', Items([]), Settings.defaultSettings()),
      ]);

      model.invalidatePreferencesCache();

      final second = await model.getSavedPreferences();
      expect(second.length, 2);
      expect(mock.loadAllCallCount, 2);
    });

    test('returns empty list when no preferences exist', () async {
      final mock = MockPreferencesHistory();
      final model = AppModel(preferencesHistory: mock);

      final result = await model.getSavedPreferences();

      expect(result, isEmpty);
      expect(mock.loadAllCallCount, 1);
    });
  });
}
