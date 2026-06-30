@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:how_many_mobile_meeple/api/http_retry_client.dart';
import '../helpers/sync_mock_client.dart';
import 'package:how_many_mobile_meeple/guided_flow/step4_game_style.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _buildTestWidget(AppModel model) {
  return MaterialApp(
    home: Scaffold(
      body: ChangeNotifierProvider.value(
        value: model,
        child: const SingleChildScrollView(
          child: Step4GameStyle(),
        ),
      ),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    HttpRetryClient.setDelayFunction((_) async {});
    HttpRetryClient.setTestClient(
        SyncMockClient((_) => http.Response('[]', 200)));
  });

  tearDown(() {
    HttpRetryClient.resetTestClient();
    HttpRetryClient.resetDelayFunction();
  });

  group('Step4GameStyle', () {
    testWidgets('displays header', (WidgetTester tester) async {
      final model = AppModel();

      await tester.pumpWidget(_buildTestWidget(model));

      expect(find.text('Game Style'), findsOneWidget);
      expect(find.text('Choose difficulty and mechanics'), findsOneWidget);
    });

    testWidgets('displays difficulty section', (WidgetTester tester) async {
      final model = AppModel();

      await tester.pumpWidget(_buildTestWidget(model));

      expect(find.text('Difficulty'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Gateway'), findsOneWidget);
      expect(find.text('Strategy'), findsOneWidget);
      expect(find.text('Heavy'), findsOneWidget);
      expect(find.text('Expert'), findsOneWidget);
    });

    testWidgets('tapping difficulty panel updates setting',
        (WidgetTester tester) async {
      final model = AppModel();

      await tester.pumpWidget(_buildTestWidget(model));

      await tester.tap(find.text('Gateway'));
      await tester.pump();

      final setting = model.settings.setting(Settings.filterComplexity.name);
      expect(setting.value, 2.0);
      expect(setting.enabled, true);
    });

    testWidgets('displays mechanics categories', (WidgetTester tester) async {
      final model = AppModel();

      await tester.pumpWidget(_buildTestWidget(model));

      expect(find.text('Mechanics (Optional)'), findsOneWidget);
      expect(find.text('Core Gameplay'), findsOneWidget);
      expect(find.text('Player Interaction'), findsOneWidget);
      expect(find.text('Randomness & Input'), findsOneWidget);
    });

    testWidgets('displays mechanic chips', (WidgetTester tester) async {
      final model = AppModel();

      await tester.pumpWidget(_buildTestWidget(model));

      expect(find.text('Hand Management'), findsOneWidget);
      expect(find.text('Set Collection'), findsOneWidget);
      expect(find.text('Dice Rolling'), findsOneWidget);
      expect(find.text('Cooperative Play'), findsOneWidget);
    });

    testWidgets('displays unplayed only toggle', (WidgetTester tester) async {
      final model = AppModel();

      await tester.pumpWidget(_buildTestWidget(model));

      expect(find.text('Unplayed only'), findsOneWidget);
    });
  });

  group('Step4GameStyle mechanics interaction', () {
    testWidgets('tapping Hand Management chip adds it to selection',
        (WidgetTester tester) async {
      final model = AppModel();

      await tester.pumpWidget(_buildTestWidget(model));

      // Hand Management is in 'Core Gameplay' — visible above fold
      await tester.tap(find.text('Hand Management'));
      await tester.pump();

      final setting = model.settings.setting(Settings.filterMechanics.name);
      expect(setting.value, contains('Hand Management'));
      expect(setting.enabled, true);
    });

    testWidgets('tapping selected mechanic removes it',
        (WidgetTester tester) async {
      final model = AppModel();
      final setting = model.settings.setting(Settings.filterMechanics.name);
      setting.value = ['Hand Management'];
      setting.enabled = true;
      model.settings.updateSetting(setting);

      await tester.pumpWidget(_buildTestWidget(model));

      await tester.tap(find.text('Hand Management'));
      await tester.pump();

      expect(setting.value, isEmpty);
      expect(setting.enabled, false);
    });

    testWidgets('displays difficulty description info box',
        (WidgetTester tester) async {
      final model = AppModel();

      await tester.pumpWidget(_buildTestWidget(model));

      expect(find.text('Show games of any complexity'), findsOneWidget);
    });
  });
}
