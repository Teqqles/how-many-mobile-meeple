@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_many_mobile_meeple/components/drawer_settings_column.dart';
import 'package:how_many_mobile_meeple/model/app_preferences.dart';
import 'package:how_many_mobile_meeple/model/item.dart';
import 'package:how_many_mobile_meeple/model/items.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';
import 'package:how_many_mobile_meeple/storage/preferences_history_interface.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakePreferencesHistory implements PreferencesHistoryInterface {
  final List<AppPreferences> _prefs;

  _FakePreferencesHistory([this._prefs = const []]);

  @override
  Future<List<AppPreferences>> loadAllPreferences() async => _prefs;

  @override
  Future<AppPreferences> loadPreference(int preferenceId) async =>
      throw UnimplementedError();

  @override
  Future<void> storePreference(AppPreferences preferences) async {}

  @override
  Future<bool> deletePreference(String preferenceId) async => true;
}

Widget _buildTestApp(AppModel model, DrawerSettingsColumn column) {
  return ChangeNotifierProvider<AppModel>.value(
    value: model,
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => FutureBuilder<List<Widget>>(
            future: column.drawerContent(context, model, 0),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const CircularProgressIndicator();
              }
              return Column(children: snapshot.data!);
            },
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

  group('DrawerSettingsColumn', () {
    testWidgets('renders heading plus saved setting titles', (tester) async {
      final prefs = [
        AppPreferences(
            '1',
            'Game Night',
            Items([Item('user1', itemType: ItemType.collection)]),
            Settings.defaultSettings()),
        AppPreferences(
            '2',
            'Solo Play',
            Items([Item('user2', itemType: ItemType.collection)]),
            Settings.defaultSettings()),
      ];

      final model =
          AppModel(preferencesHistory: _FakePreferencesHistory(prefs));
      final column = DrawerSettingsColumn('Saved Settings');

      await tester.pumpWidget(_buildTestApp(model, column));
      await tester.pumpAndSettle();

      expect(find.text('Saved Settings'), findsOneWidget);
      expect(find.text('Game Night'), findsOneWidget);
      expect(find.text('Solo Play'), findsOneWidget);
    });

    testWidgets('renders only heading when no saved preferences',
        (tester) async {
      final model = AppModel(preferencesHistory: _FakePreferencesHistory([]));
      final column = DrawerSettingsColumn('My Section');

      await tester.pumpWidget(_buildTestApp(model, column));
      await tester.pumpAndSettle();

      expect(find.text('My Section'), findsOneWidget);
      expect(find.byType(InkWell), findsNothing);
    });
  });
}
