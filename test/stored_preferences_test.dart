import 'dart:convert';

import 'package:how_many_mobile_meeple/model/setting.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';
import 'package:how_many_mobile_meeple/storage/stored_preferences.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test/test.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

main() {
  var firstSetting = Setting("key-1", value: "value-1");
  var secondSetting = Setting("key-2", value: "value-2");
  var settings = Settings(
      {firstSetting.name: firstSetting, secondSetting.name: secondSetting});
  var singleSetting = Settings({firstSetting.name: firstSetting});

  group('saveSettings', () {
    test('returns true and stores setting data when supplied', () async {
      final prefs = MockSharedPreferences();

      when(prefs.setString(firstSetting.name, json.encode(firstSetting)))
          .thenAnswer(((_) => Future(() => true)));
      when(prefs.setString(secondSetting.name, json.encode(secondSetting)))
          .thenAnswer(((_) => Future(() => true)));

      var storedPreferences = StoredPreferences(prefs);

      expect(await storedPreferences.saveSettings(settings), isTrue);

      verify(prefs.setString(firstSetting.name, json.encode(firstSetting)))
          .called(1);
      verify(prefs.setString(secondSetting.name, json.encode(secondSetting)))
          .called(1);
    });
  });
  group('loadSettings', () {
    test('returns settings stored in shared properties', () async {
      final prefs = MockSharedPreferences();

      var emptySettings =
          Settings({firstSetting.name: null, secondSetting.name: null});

      when(prefs.containsKey(firstSetting.name)).thenReturn(true);
      when(prefs.containsKey(secondSetting.name)).thenReturn(true);
      when(prefs.getString(firstSetting.name))
          .thenAnswer(((_) => json.encode(firstSetting)));
      when(prefs.getString(secondSetting.name))
          .thenAnswer(((_) => json.encode(secondSetting)));

      var storedPreferences = StoredPreferences(prefs);

      expect(await storedPreferences.loadSettings(emptySettings), settings);

      verify(prefs.getString(firstSetting.name)).called(1);
      verify(prefs.getString(secondSetting.name)).called(1);
    });
    test('checks for a setting before trying to load it', () async {
      final prefs = MockSharedPreferences();

      var emptySettings =
          Settings({firstSetting.name: null, secondSetting.name: null});

      when(prefs.containsKey(firstSetting.name)).thenReturn(true);
      when(prefs.containsKey(secondSetting.name)).thenReturn(false);
      when(prefs.getString(firstSetting.name))
          .thenAnswer(((_) => json.encode(firstSetting)));
      when(prefs.getString(secondSetting.name)).thenThrow(Exception);

      var storedPreferences = StoredPreferences(prefs);

      expect(
          await storedPreferences.loadSettings(emptySettings), singleSetting);

      verify(prefs.containsKey(firstSetting.name)).called(1);
      verify(prefs.getString(firstSetting.name)).called(1);
      verify(prefs.containsKey(secondSetting.name)).called(1);
      verifyNever(prefs.getString(secondSetting.name));
    });
  });
}
