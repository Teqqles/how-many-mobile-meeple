@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_many_mobile_meeple/guided_flow/step2_whos_playing.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _buildTestWidget(AppModel model) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: ChangeNotifierProvider.value(
          value: model,
          child: const Step2WhosPlaying(),
        ),
      ),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Step2WhosPlaying', () {
    testWidgets('displays header and default player count',
        (WidgetTester tester) async {
      final model = AppModel();

      await tester.pumpWidget(_buildTestWidget(model));

      expect(find.text("Who's Playing?"), findsOneWidget);
      expect(find.text('Select the number of players'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('players'), findsOneWidget);
    });

    testWidgets('shows singular label for 1 player',
        (WidgetTester tester) async {
      final model = AppModel();
      final setting =
          model.settings.setting(Settings.filterNumberOfPlayers.name);
      setting.value = 1;
      setting.enabled = true;
      model.settings.updateSetting(setting);

      await tester.pumpWidget(_buildTestWidget(model));

      expect(find.text('player'), findsOneWidget);
      expect(find.text('players'), findsNothing);
    });

    testWidgets('displays all preset chips', (WidgetTester tester) async {
      final model = AppModel();

      await tester.pumpWidget(_buildTestWidget(model));

      expect(find.text('Solo (1)'), findsOneWidget);
      expect(find.text('Couple (2)'), findsOneWidget);
      expect(find.text('Family (4)'), findsOneWidget);
      expect(find.text('Gamers (5)'), findsOneWidget);
      expect(find.text('Party (8)'), findsOneWidget);
    });

    testWidgets('tapping preset chip updates player count',
        (WidgetTester tester) async {
      final model = AppModel();

      await tester.pumpWidget(_buildTestWidget(model));

      await tester.tap(find.text('Couple (2)'));
      await tester.pump();

      expect(find.text('2'), findsOneWidget);
      expect(find.text('players'), findsOneWidget);

      final setting =
          model.settings.setting(Settings.filterNumberOfPlayers.name);
      expect(setting.value, 2);
      expect(setting.enabled, true);
    });

    testWidgets('slider updates player count', (WidgetTester tester) async {
      final model = AppModel();

      await tester.pumpWidget(_buildTestWidget(model));

      final slider = find.byType(Slider);
      expect(slider, findsOneWidget);

      // Drag slider to minimum (left edge)
      final sliderWidget = tester.widget<Slider>(slider);
      expect(sliderWidget.min, 1.0);
      expect(sliderWidget.max, 10.0);
    });

    testWidgets('displays info message', (WidgetTester tester) async {
      final model = AppModel();

      await tester.pumpWidget(_buildTestWidget(model));

      expect(
        find.text("We'll find games that work well with this player count"),
        findsOneWidget,
      );
    });

    testWidgets('preset chip reflects current player count as selected',
        (WidgetTester tester) async {
      final model = AppModel();

      await tester.pumpWidget(_buildTestWidget(model));

      // Default is 5 which matches 'Gamers (5)'
      await tester.tap(find.text('Solo (1)'));
      await tester.pump();

      // After tapping Solo, tapping Gamers again should restore
      await tester.tap(find.text('Gamers (5)'));
      await tester.pump();

      final setting =
          model.settings.setting(Settings.filterNumberOfPlayers.name);
      expect(setting.value, 5);
    });

    testWidgets('slider has correct min and max bounds',
        (WidgetTester tester) async {
      final model = AppModel();

      await tester.pumpWidget(_buildTestWidget(model));

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.min, 1.0);
      expect(slider.max, 10.0);
      expect(slider.divisions, 9);
    });

    testWidgets('player count at maximum boundary displays correctly',
        (WidgetTester tester) async {
      final model = AppModel();
      final setting =
          model.settings.setting(Settings.filterNumberOfPlayers.name);
      setting.value = 10;
      setting.enabled = true;
      model.settings.updateSetting(setting);

      await tester.pumpWidget(_buildTestWidget(model));

      expect(find.text('10'), findsOneWidget);
      expect(find.text('players'), findsOneWidget);
    });
  });
}
