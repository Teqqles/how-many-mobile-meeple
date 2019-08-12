import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:how_many_mobile_meeple/components/drawer_saved_setting.dart';
import 'package:how_many_mobile_meeple/components/drawer_settings_column.dart';
import 'package:how_many_mobile_meeple/model/app_preferences.dart';
import 'package:how_many_mobile_meeple/model/item.dart';
import 'package:how_many_mobile_meeple/model/items.dart';
import 'package:how_many_mobile_meeple/model/setting.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';
import 'package:how_many_mobile_meeple/storage/preferences_history.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

class MockPreferencesHistory extends Mock implements PreferencesHistory {}

class MockBuildContext extends Mock implements BuildContext {}

main() {
//  group('build', () {
//    test('returns an empty widget when no preferences are stored in the db',
//        () async {
//      final history = MockPreferencesHistory();
//      final context = MockBuildContext();
//
//      when(history.loadAllPreferences()).thenAnswer(((_) => Future(() => [])));
//
//      var drawerSettingsColumn =
//          DrawerSettingsColumn("My Drawer Column Name", history: history);
//
//      expect(drawerSettingsColumn.build(context), null);
//
//      verify(history.loadAllPreferences()).called(1);
//    });
//    test('returns a column containing preferences when found', () async {
//      final history = MockPreferencesHistory();
//      final context = MockBuildContext();
//      String drawerSectionName = "My Drawer Column Name";
//
//      Widget expectedGeneratedWidget = Column(
//        children: <Widget>[Text("Wibble")],
//      );
//
//      when(history.loadAllPreferences()).thenAnswer(((_) => Future(() => [])));
//
//      var drawerSettingsColumn =
//          DrawerSettingsColumn(drawerSectionName, history: history);
//
//      expect(drawerSettingsColumn.build(context), expectedGeneratedWidget);
//
//      verify(history.loadAllPreferences()).called(1);
//    });
//  });

  group('settingsFromDb', () {
    test('returns empty when no settings are present in the database',
        () async {
      final history = MockPreferencesHistory();
      final context = MockBuildContext();

      when(history.loadAllPreferences()).thenAnswer((_) => Future(() => []));

      var drawerSettingsColumn =
          DrawerSettingsColumn("Drawer Settings Name", history: history);

      expect(await drawerSettingsColumn.settingsFromDb(context), []);

      verify(history.loadAllPreferences()).called(1);
    });

    test(
        'returns a container build list of preferences when present in the database',
        () async {
      final history = MockPreferencesHistory();
      final context = MockBuildContext();

      final prefs = AppPreferences(
          'hashcode_id',
          'my preferences',
          Items([Item('item name')]),
          Settings({'setting': Setting('setting name')}));

      when(history.loadAllPreferences())
          .thenAnswer((_) => Future(() => [prefs]));

      var drawerSettingsColumn =
          DrawerSettingsColumn("Drawer Settings Name", history: history);

      expect(await drawerSettingsColumn.settingsFromDb(context),
          DrawerSavedSetting.preferencesToDrawSettings(prefs, context));
    });
  });
}
