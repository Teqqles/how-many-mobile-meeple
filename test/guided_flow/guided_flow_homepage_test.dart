import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_many_mobile_meeple/guided_flow_homepage.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';
import 'package:how_many_mobile_meeple/tour_tips/tour_tip_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _buildTestApp(AppModel model) {
  return MaterialApp(
    home: ChangeNotifierProvider.value(
      value: model,
      child: GuidedFlowHomePage(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TourTipService.resetForTesting();
    SharedPreferences.setMockInitialValues({'tour_tips_disabled': true});
  });

  group('GuidedFlowHomePage advanced mode stability', () {
    testWidgets(
        'stays in advanced mode when model notifies listeners after switching',
        (WidgetTester tester) async {
      final model = AppModel();

      // Pre-set advanced mode before the widget loads so loadStoredData picks
      // it up without triggering async network calls
      final setting = model.settings.setting(Settings.preferAdvancedMode.name);
      setting.value = true;
      setting.enabled = true;
      model.settings.updateSetting(setting);
      model.hasLoadedPersistedData = true;

      await tester.pumpWidget(_buildTestApp(model));
      await tester.pump(const Duration(milliseconds: 100));

      // Guided flow step indicator must not be present in advanced mode
      expect(find.text('Step 1 of 5'), findsNothing);

      // Simulate a model notification (e.g. a filter widget updating state)
      model.refreshState();
      await tester.pump(const Duration(milliseconds: 100));

      // Must still be in advanced mode - not flipped back to guided flow
      expect(find.text('Step 1 of 5'), findsNothing);
    });

    testWidgets('shows guided flow by default', (WidgetTester tester) async {
      final model = AppModel();
      model.hasLoadedPersistedData = true;

      await tester.pumpWidget(_buildTestApp(model));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Step 1 of 5'), findsOneWidget);
    });

    testWidgets('switches back to guided flow when preference is cleared',
        (WidgetTester tester) async {
      final model = AppModel();
      model.hasLoadedPersistedData = true;

      final setting = model.settings.setting(Settings.preferAdvancedMode.name);
      setting.value = true;
      setting.enabled = true;
      model.settings.updateSetting(setting);

      await tester.pumpWidget(_buildTestApp(model));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Step 1 of 5'), findsNothing);

      // Disable advanced mode
      setting.value = false;
      model.settings.updateSetting(setting);
      model.refreshState();
      // Two pumps: one for the Consumer rebuild, one for the postFrameCallback
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Step 1 of 5'), findsOneWidget);
    });
  });
}
