@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';
import 'package:how_many_mobile_meeple/settings_summary_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _buildTestWidget(AppModel model) {
  return ChangeNotifierProvider<AppModel>.value(
    value: model,
    child: MaterialApp(
      home: SettingsSummaryPage(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SettingsSummaryPage', () {
    testWidgets('displays page header', (tester) async {
      final model = AppModel();
      await tester.pumpWidget(_buildTestWidget(model));
      await tester.pumpAndSettle();

      expect(find.text('Your Game Preferences'), findsOneWidget);
      expect(find.text("Here's what you're looking for"), findsOneWidget);
    });

    testWidgets('displays player count section', (tester) async {
      final model = AppModel();
      await tester.pumpWidget(_buildTestWidget(model));
      await tester.pumpAndSettle();

      expect(find.text('Player Count'), findsOneWidget);
    });

    testWidgets('displays play time section', (tester) async {
      final model = AppModel();
      await tester.pumpWidget(_buildTestWidget(model));
      await tester.pumpAndSettle();

      expect(find.text('Play Time'), findsOneWidget);
    });

    testWidgets('displays difficulty section', (tester) async {
      final model = AppModel();
      await tester.pumpWidget(_buildTestWidget(model));
      await tester.pumpAndSettle();

      expect(find.text('Difficulty'), findsOneWidget);
    });

    testWidgets('shows correct player count value', (tester) async {
      final model = AppModel();
      final setting =
          model.settings.setting(Settings.filterNumberOfPlayers.name);
      setting.value = 3;
      setting.enabled = true;
      model.settings.updateSetting(setting);

      await tester.pumpWidget(_buildTestWidget(model));
      await tester.pumpAndSettle();

      expect(find.text('3 players'), findsOneWidget);
    });

    testWidgets('shows singular player label for 1 player', (tester) async {
      final model = AppModel();
      final setting =
          model.settings.setting(Settings.filterNumberOfPlayers.name);
      setting.value = 1;
      setting.enabled = true;
      model.settings.updateSetting(setting);

      await tester.pumpWidget(_buildTestWidget(model));
      await tester.pumpAndSettle();

      expect(find.text('1 player'), findsOneWidget);
    });

    testWidgets('displays action buttons', (tester) async {
      final model = AppModel();
      await tester.pumpWidget(_buildTestWidget(model));
      await tester.pumpAndSettle();

      expect(find.text('Go Back'), findsOneWidget);
      expect(find.text('Find Games'), findsOneWidget);
    });

    testWidgets('displays game sources section', (tester) async {
      final model = AppModel();
      await tester.pumpWidget(_buildTestWidget(model));
      await tester.pumpAndSettle();

      expect(find.text('Game Sources'), findsOneWidget);
      expect(find.text('No sources selected'), findsOneWidget);
    });

    testWidgets('displays additional filters section', (tester) async {
      final model = AppModel();

      await tester.pumpWidget(_buildTestWidget(model));
      await tester.pumpAndSettle();

      // Scroll to find additional filters
      await tester.scrollUntilVisible(
        find.text('Additional Filters'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Additional Filters'), findsOneWidget);
      expect(find.text('Include Expansions'), findsOneWidget);
    });
  });
}
