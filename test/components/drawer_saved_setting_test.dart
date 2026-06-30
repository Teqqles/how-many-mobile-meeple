@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_many_mobile_meeple/components/drawer_saved_setting.dart';
import 'package:how_many_mobile_meeple/model/app_preferences.dart';
import 'package:how_many_mobile_meeple/model/item.dart';
import 'package:how_many_mobile_meeple/model/items.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';
import 'package:how_many_mobile_meeple/storage/preferences_history_interface.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakePreferencesHistory implements PreferencesHistoryInterface {
  bool deleteCalled = false;
  String? deletedId;

  @override
  Future<bool> deletePreference(String preferenceId) async {
    deleteCalled = true;
    deletedId = preferenceId;
    return true;
  }

  @override
  Future<List<AppPreferences>> loadAllPreferences() async => [];

  @override
  Future<AppPreferences> loadPreference(int preferenceId) async =>
      throw UnimplementedError();

  @override
  Future<void> storePreference(AppPreferences preferences) async {}
}

AppPreferences _makePreferences({String? id, String title = 'Test Prefs'}) {
  return AppPreferences(
    id,
    title,
    Items([Item('testuser', itemType: ItemType.collection)]),
    Settings.defaultSettings(),
  );
}

Widget _buildTestApp(
  AppModel model,
  AppPreferences preferences, {
  PreferencesHistoryInterface? storage,
  int index = 0,
}) {
  return ChangeNotifierProvider<AppModel>.value(
    value: model,
    child: MaterialApp(
      routes: {'/settings': (_) => const Scaffold(body: Text('Settings'))},
      home: Scaffold(
        body: Builder(
          builder: (context) => DrawerSavedSetting(
            preferences.title,
            preferences,
            context,
            index: index,
            storage: storage,
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DrawerSavedSetting', () {
    testWidgets('renders preferences title as tappable text', (tester) async {
      final model = AppModel();
      final prefs = _makePreferences(id: '1', title: 'My Saved Game');

      await tester.pumpWidget(_buildTestApp(model, prefs));
      await tester.pump();

      expect(find.text('My Saved Game'), findsOneWidget);
      final inkWell = tester.widget<InkWell>(find.ancestor(
        of: find.text('My Saved Game'),
        matching: find.byType(InkWell),
      ));
      expect(inkWell.onTap, isNotNull);
    });

    testWidgets('delete button calls storage and model when id is not null',
        (tester) async {
      final model = AppModel();
      final storage = _FakePreferencesHistory();
      final prefs = _makePreferences(id: 'pref-123');

      int notifyCount = 0;
      model.addListener(() => notifyCount++);

      await tester.pumpWidget(_buildTestApp(model, prefs, storage: storage));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pump();

      expect(storage.deleteCalled, isTrue);
      expect(storage.deletedId, 'pref-123');
      expect(notifyCount, greaterThan(0));
    });

    testWidgets('delete button shows snackbar when id is null', (tester) async {
      final model = AppModel();
      final storage = _FakePreferencesHistory();
      final prefs = _makePreferences(id: null);

      await tester.pumpWidget(_buildTestApp(model, prefs, storage: storage));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pump();

      expect(find.text('Cannot delete unsaved preference'), findsOneWidget);
      expect(storage.deleteCalled, isFalse);
    });

    testWidgets('renders without error at index 0 and 1', (tester) async {
      final model = AppModel();
      final prefs = _makePreferences(id: '1');

      await tester.pumpWidget(_buildTestApp(model, prefs, index: 0));
      await tester.pump();
      expect(find.text('Test Prefs'), findsOneWidget);

      await tester.pumpWidget(_buildTestApp(model, prefs, index: 1));
      await tester.pump();
      expect(find.text('Test Prefs'), findsOneWidget);
    });
  });
}
