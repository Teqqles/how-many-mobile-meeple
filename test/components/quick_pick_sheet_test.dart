import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_many_mobile_meeple/components/quick_pick_sheet.dart';
import 'package:how_many_mobile_meeple/model/item.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _buildTestApp({AppModel? model}) {
  final appModel = model ?? AppModel();
  return ChangeNotifierProvider<AppModel>.value(
    value: appModel,
    child: MaterialApp(
      onGenerateRoute: (settings) => MaterialPageRoute(
        builder: (_) => Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => QuickPickSheet.show(context),
              child: const Text('Open'),
            ),
          ),
        ),
        settings: settings,
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => QuickPickSheet.show(context),
            child: const Text('Open'),
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

  group('QuickPickSheet', () {
    testWidgets('displays all three chip rows', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Players'), findsOneWidget);
      expect(find.text('Time'), findsOneWidget);
      expect(find.text('Weight'), findsOneWidget);
    });

    testWidgets('displays player options', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('2'), findsOneWidget);
      expect(find.text('3-4'), findsOneWidget);
      expect(find.text('5+'), findsOneWidget);
    });

    testWidgets('displays time options', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('< 30 min'), findsOneWidget);
      expect(find.text('30-60 min'), findsOneWidget);
      expect(find.text('~60 min'), findsOneWidget);
      expect(find.text('90+ min'), findsOneWidget);
    });

    testWidgets('displays weight options', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.text('Heavy'), findsOneWidget);
    });

    testWidgets('displays Go button when source exists', (tester) async {
      final model = AppModel();
      await model.addItem(Item('testuser'));
      await tester.pumpWidget(_buildTestApp(model: model));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Go!'), findsOneWidget);
    });

    testWidgets('tapping a chip selects it', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('3-4'));
      await tester.pumpAndSettle();

      final chip = tester.widget<ChoiceChip>(
        find.ancestor(
          of: find.text('3-4'),
          matching: find.byType(ChoiceChip),
        ),
      );
      expect(chip.selected, isTrue);
    });

    testWidgets('tapping a selected chip deselects it', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('3-4'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('3-4'));
      await tester.pumpAndSettle();

      final chip = tester.widget<ChoiceChip>(
        find.ancestor(
          of: find.text('3-4'),
          matching: find.byType(ChoiceChip),
        ),
      );
      expect(chip.selected, isFalse);
    });

    testWidgets('Go button is disabled when no source is added',
        (tester) async {
      final model = AppModel();
      await tester.pumpWidget(_buildTestApp(model: model));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Add a source first'), findsOneWidget);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('Go button applies player filter to model', (tester) async {
      final model = AppModel();
      await model.addItem(Item('testuser'));
      await tester.pumpWidget(_buildTestApp(model: model));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('5+'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Go!'));
      await tester.pumpAndSettle();

      final playerSetting =
          model.settings.setting(Settings.filterNumberOfPlayers.name);
      expect(playerSetting.value, 5);
      expect(playerSetting.enabled, isTrue);
    });

    testWidgets('Go button applies time filter to model', (tester) async {
      final model = AppModel();
      await model.addItem(Item('testuser'));
      await tester.pumpWidget(_buildTestApp(model: model));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('30-60 min'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Go!'));
      await tester.pumpAndSettle();

      final maxTimeSetting =
          model.settings.setting(Settings.filterMaximumTimeToPlay.name);
      final minTimeSetting =
          model.settings.setting(Settings.filterMinimumTimeToPlay.name);
      expect(maxTimeSetting.value, 60);
      expect(minTimeSetting.value, 30);
      expect(maxTimeSetting.enabled, isTrue);
      expect(minTimeSetting.enabled, isTrue);
    });

    testWidgets('Go button applies weight filter to model', (tester) async {
      final model = AppModel();
      await model.addItem(Item('testuser'));
      await tester.pumpWidget(_buildTestApp(model: model));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Heavy'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Go!'));
      await tester.pumpAndSettle();

      final complexitySetting =
          model.settings.setting(Settings.filterComplexity.name);
      expect(complexitySetting.value, 5.0);
      expect(complexitySetting.enabled, isTrue);
    });

    testWidgets('restores last selections from model settings', (tester) async {
      final model = AppModel();
      await model.addItem(Item('testuser'));

      final playerSetting =
          model.settings.setting(Settings.filterNumberOfPlayers.name);
      playerSetting.value = 4;
      playerSetting.enabled = true;
      model.settings.updateSetting(playerSetting);

      final maxTimeSetting =
          model.settings.setting(Settings.filterMaximumTimeToPlay.name);
      maxTimeSetting.value = 90;
      maxTimeSetting.enabled = true;
      model.settings.updateSetting(maxTimeSetting);

      final complexitySetting =
          model.settings.setting(Settings.filterComplexity.name);
      complexitySetting.value = 2.0;
      complexitySetting.enabled = true;
      model.settings.updateSetting(complexitySetting);

      await tester.pumpWidget(_buildTestApp(model: model));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final playerChip = tester.widget<ChoiceChip>(
        find.ancestor(of: find.text('3-4'), matching: find.byType(ChoiceChip)),
      );
      expect(playerChip.selected, isTrue);

      final timeChip = tester.widget<ChoiceChip>(
        find.ancestor(
            of: find.text('~60 min'), matching: find.byType(ChoiceChip)),
      );
      expect(timeChip.selected, isTrue);

      final weightChip = tester.widget<ChoiceChip>(
        find.ancestor(
            of: find.text('Light'), matching: find.byType(ChoiceChip)),
      );
      expect(weightChip.selected, isTrue);
    });

    testWidgets('Go button without selections does not alter filters',
        (tester) async {
      final model = AppModel();
      await model.addItem(Item('testuser'));
      final defaultPlayers =
          model.settings.setting(Settings.filterNumberOfPlayers.name).value;
      final defaultMaxTime =
          model.settings.setting(Settings.filterMaximumTimeToPlay.name).value;
      final defaultComplexity =
          model.settings.setting(Settings.filterComplexity.name).value;

      await tester.pumpWidget(_buildTestApp(model: model));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Go!'));
      await tester.pumpAndSettle();

      expect(model.settings.setting(Settings.filterNumberOfPlayers.name).value,
          defaultPlayers);
      expect(
          model.settings.setting(Settings.filterMaximumTimeToPlay.name).value,
          defaultMaxTime);
      expect(model.settings.setting(Settings.filterComplexity.name).value,
          defaultComplexity);
    });
  });
}
