@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_many_mobile_meeple/guided_flow/step3_time_available.dart';
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
          child: const Step3TimeAvailable(),
        ),
      ),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Step3TimeAvailable', () {
    testWidgets('displays header and default time range',
        (WidgetTester tester) async {
      final model = AppModel();

      await tester.pumpWidget(_buildTestWidget(model));

      expect(find.text('Time Available'), findsOneWidget);
      expect(find.text('How long do you want to play?'), findsOneWidget);
    });

    testWidgets('displays time preset chips', (WidgetTester tester) async {
      final model = AppModel();

      await tester.pumpWidget(_buildTestWidget(model));

      expect(find.text('30 min'), findsOneWidget);
      expect(find.text('60 min'), findsOneWidget);
      expect(find.text('90 min'), findsOneWidget);
      expect(find.text('2h+'), findsOneWidget);
    });

    testWidgets('tapping preset chip updates time settings',
        (WidgetTester tester) async {
      final model = AppModel();

      await tester.pumpWidget(_buildTestWidget(model));

      await tester.tap(find.text('60 min'));
      await tester.pump();

      final minSetting =
          model.settings.setting(Settings.filterMinimumTimeToPlay.name);
      final maxSetting =
          model.settings.setting(Settings.filterMaximumTimeToPlay.name);
      expect(maxSetting.value, 60);
      expect(minSetting.value, 30);
      expect(minSetting.enabled, true);
      expect(maxSetting.enabled, true);
    });

    testWidgets('displays semantic label for time range',
        (WidgetTester tester) async {
      final model = AppModel();
      final maxSetting =
          model.settings.setting(Settings.filterMaximumTimeToPlay.name);
      maxSetting.value = 60;
      model.settings.updateSetting(maxSetting);

      await tester.pumpWidget(_buildTestWidget(model));

      expect(find.text('Short'), findsOneWidget);
    });

    testWidgets('displays range slider', (WidgetTester tester) async {
      final model = AppModel();

      await tester.pumpWidget(_buildTestWidget(model));

      final rangeSlider = find.byType(RangeSlider);
      expect(rangeSlider, findsOneWidget);

      final widget = tester.widget<RangeSlider>(rangeSlider);
      expect(widget.min, 15.0);
      expect(widget.max, 300.0);
    });

    testWidgets('displays Quick and Epic labels', (WidgetTester tester) async {
      final model = AppModel();

      await tester.pumpWidget(_buildTestWidget(model));

      expect(find.textContaining('Quick'), findsWidgets);
      expect(find.textContaining('Epic'), findsWidgets);
    });

    testWidgets('displays info message', (WidgetTester tester) async {
      final model = AppModel();

      await tester.pumpWidget(_buildTestWidget(model));

      expect(
        find.text("We'll find games that fit within your time budget"),
        findsOneWidget,
      );
    });

    testWidgets('displays Quick label at 30 min boundary',
        (WidgetTester tester) async {
      final model = AppModel();
      final maxSetting =
          model.settings.setting(Settings.filterMaximumTimeToPlay.name);
      maxSetting.value = 30;
      model.settings.updateSetting(maxSetting);

      await tester.pumpWidget(_buildTestWidget(model));

      expect(find.text('Quick'), findsWidgets);
    });

    testWidgets('displays Epic label at 121+ min boundary',
        (WidgetTester tester) async {
      final model = AppModel();
      final maxSetting =
          model.settings.setting(Settings.filterMaximumTimeToPlay.name);
      maxSetting.value = 150;
      model.settings.updateSetting(maxSetting);

      await tester.pumpWidget(_buildTestWidget(model));

      expect(find.text('Epic'), findsWidgets);
    });

    testWidgets('range slider has correct min and max bounds',
        (WidgetTester tester) async {
      final model = AppModel();

      await tester.pumpWidget(_buildTestWidget(model));

      final slider = tester.widget<RangeSlider>(find.byType(RangeSlider));
      expect(slider.min, 15.0);
      expect(slider.max, 300.0);
      expect(slider.divisions, 19);
    });
  });
}
