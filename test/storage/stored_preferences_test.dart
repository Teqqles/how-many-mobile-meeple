import 'dart:convert';

import 'package:how_many_mobile_meeple/model/setting.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';
import 'package:how_many_mobile_meeple/storage/stored_preferences.dart';
import 'package:mockito/mockito.dart';
import 'package:how_many_mobile_meeple/model/items.dart';
import 'package:how_many_mobile_meeple/model/item.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test/test.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

main() {
  var firstSetting = Setting("key-1", value: "value-1");
  var secondSetting = Setting("key-2", value: "value-2");
  var settings = Settings(
      {firstSetting.name: firstSetting, secondSetting.name: secondSetting});

  var emptySettings =
      Settings({firstSetting.name: null, secondSetting.name: null});

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

      when(prefs.containsKey(firstSetting.name)).thenReturn(true);
      when(prefs.containsKey(secondSetting.name)).thenReturn(true);
      when(prefs.getString(firstSetting.name))
          .thenAnswer(((_) => json.encode(firstSetting)));
      when(prefs.getString(secondSetting.name))
          .thenAnswer(((_) => json.encode(secondSetting)));

      var storedPreferences = StoredPreferences(prefs);

      expect(await storedPreferences.loadSettings(emptySettings), settings);

      verify(prefs.containsKey(firstSetting.name)).called(1);
      verify(prefs.getString(firstSetting.name)).called(1);
      verify(prefs.containsKey(secondSetting.name)).called(1);
      verify(prefs.getString(secondSetting.name)).called(1);
    });
    test('checks for a setting before trying to load it', () async {
      final prefs = MockSharedPreferences();

      when(prefs.containsKey(firstSetting.name)).thenReturn(true);
      when(prefs.containsKey(secondSetting.name)).thenReturn(false);
      when(prefs.getString(firstSetting.name))
          .thenAnswer(((_) => json.encode(firstSetting)));
      when(prefs.getString(secondSetting.name)).thenThrow(Exception);

      var storedPreferences = StoredPreferences(prefs);

      var expectedSetting = emptySettings.clone();
      expectedSetting.updateSetting(firstSetting);

      expect(
          await storedPreferences.loadSettings(emptySettings), expectedSetting);

      verify(prefs.containsKey(firstSetting.name)).called(1);
      verify(prefs.getString(firstSetting.name)).called(1);
      verify(prefs.containsKey(secondSetting.name)).called(1);
      verifyNever(prefs.getString(secondSetting.name));
    });
  });

  Item firstItem = Item("boardGameGeekUser");
  Item secondItem = Item("63321157");
  Items items = Items([firstItem, secondItem]);
  var maxItemsToLoad = 2;

  group('saveItems', () {
    test('returns true and stores item data when supplied', () async {
      final prefs = MockSharedPreferences();

      when(prefs.setString(
              "${Items.itemStoreNamePrefix}0", json.encode(firstItem)))
          .thenAnswer(((_) => Future(() => true)));
      when(prefs.setString(
              "${Items.itemStoreNamePrefix}1", json.encode(secondItem)))
          .thenAnswer(((_) => Future(() => true)));

      var storedPreferences = StoredPreferences(prefs);

      expect(await storedPreferences.saveItems(items, maxItemsToLoad), isTrue);

      verify(prefs.setString(
              "${Items.itemStoreNamePrefix}0", json.encode(firstItem)))
          .called(1);
      verify(prefs.setString(
              "${Items.itemStoreNamePrefix}1", json.encode(secondItem)))
          .called(1);
    });

    test('deletes existing keys first', () async {
      final prefs = MockSharedPreferences();

      when(prefs.setString(
              "${Items.itemStoreNamePrefix}0", json.encode(firstItem)))
          .thenAnswer(((_) => Future(() => true)));
      when(prefs.setString(
              "${Items.itemStoreNamePrefix}1", json.encode(secondItem)))
          .thenAnswer(((_) => Future(() => true)));

      var storedPreferences = StoredPreferences(prefs);

      expect(await storedPreferences.saveItems(items, maxItemsToLoad), isTrue);

      verify(prefs.remove("${Items.itemStoreNamePrefix}0")).called(1);
      verify(prefs.remove("${Items.itemStoreNamePrefix}1")).called(1);

      verify(prefs.setString(
              "${Items.itemStoreNamePrefix}0", json.encode(firstItem)))
          .called(1);
      verify(prefs.setString(
              "${Items.itemStoreNamePrefix}1", json.encode(secondItem)))
          .called(1);
    });
  });

  group('loadItems', () {
    test('returns items stored in shared properties', () async {
      final prefs = MockSharedPreferences();

      when(prefs.containsKey("${Items.itemStoreNamePrefix}0")).thenReturn(true);
      when(prefs.containsKey("${Items.itemStoreNamePrefix}1")).thenReturn(true);
      when(prefs.getString("${Items.itemStoreNamePrefix}0"))
          .thenAnswer(((_) => json.encode(firstItem)));
      when(prefs.getString("${Items.itemStoreNamePrefix}1"))
          .thenAnswer(((_) => json.encode(secondItem)));

      var storedPreferences = StoredPreferences(prefs);

      expect(await storedPreferences.loadItems(maxItemsToLoad), items);

      verify(prefs.containsKey("${Items.itemStoreNamePrefix}0")).called(1);
      verify(prefs.containsKey("${Items.itemStoreNamePrefix}1")).called(1);
      verify(prefs.getString("${Items.itemStoreNamePrefix}0")).called(1);
      verify(prefs.getString("${Items.itemStoreNamePrefix}1")).called(1);
    });
    test('will not try and get items not found', () async {
      final prefs = MockSharedPreferences();

      var maxItemsToLoad = 3;

      when(prefs.containsKey("${Items.itemStoreNamePrefix}0")).thenReturn(true);
      when(prefs.containsKey("${Items.itemStoreNamePrefix}1")).thenReturn(true);
      when(prefs.containsKey("${Items.itemStoreNamePrefix}2"))
          .thenReturn(false);
      when(prefs.getString("${Items.itemStoreNamePrefix}0"))
          .thenAnswer(((_) => json.encode(firstItem)));
      when(prefs.getString("${Items.itemStoreNamePrefix}1"))
          .thenAnswer(((_) => json.encode(secondItem)));

      var storedPreferences = StoredPreferences(prefs);

      expect(await storedPreferences.loadItems(maxItemsToLoad), items);

      verify(prefs.containsKey("${Items.itemStoreNamePrefix}0")).called(1);
      verify(prefs.containsKey("${Items.itemStoreNamePrefix}1")).called(1);
      verify(prefs.containsKey("${Items.itemStoreNamePrefix}2")).called(1);
      verify(prefs.getString("${Items.itemStoreNamePrefix}0")).called(1);
      verify(prefs.getString("${Items.itemStoreNamePrefix}1")).called(1);
      verifyNever(prefs.getString("${Items.itemStoreNamePrefix}2"));
    });
  });
}
