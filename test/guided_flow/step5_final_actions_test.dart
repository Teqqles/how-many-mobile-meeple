@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_many_mobile_meeple/guided_flow/step5_final_actions.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _buildTestWidget(AppModel model, {VoidCallback? onSwitchToAdvanced}) {
  return ChangeNotifierProvider.value(
    value: model,
    child: MaterialApp(
      routes: {
        '/settings': (_) => const Scaffold(body: Text('Settings Page')),
      },
      home: Scaffold(
        body: SingleChildScrollView(
          child: Step5FinalActions(
            onSwitchToAdvanced: onSwitchToAdvanced ?? () {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Step5FinalActions', () {
    testWidgets('displays header text', (WidgetTester tester) async {
      final model = AppModel();

      await tester.pumpWidget(_buildTestWidget(model));

      expect(find.text('Ready to Find Games!'), findsOneWidget);
      expect(find.text("Choose how you'd like to explore"), findsOneWidget);
    });

    testWidgets('displays all action buttons', (WidgetTester tester) async {
      final model = AppModel();

      await tester.pumpWidget(_buildTestWidget(model));

      expect(find.text('Quick Pick'), findsOneWidget);
      expect(find.text('Random Game'), findsOneWidget);
      expect(find.text('View List'), findsOneWidget);
      expect(find.text('Shelf of Shame'), findsOneWidget);
      expect(find.text('Review My Settings'), findsOneWidget);
      expect(find.text('Save These Settings'), findsOneWidget);
    });

    testWidgets('displays advanced mode section', (WidgetTester tester) async {
      final model = AppModel();

      await tester.pumpWidget(_buildTestWidget(model));

      expect(find.text('Need more control?'), findsOneWidget);
      expect(find.text('Switch to Advanced Mode'), findsOneWidget);
    });

    testWidgets('advanced mode button calls callback',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final model = AppModel();
      var callbackFired = false;

      await tester.pumpWidget(
        _buildTestWidget(model, onSwitchToAdvanced: () => callbackFired = true),
      );

      await tester.tap(find.text('Switch to Advanced Mode'));
      await tester.pump();

      expect(callbackFired, true);
    });

    testWidgets('Review My Settings navigates to settings route',
        (WidgetTester tester) async {
      final model = AppModel();

      await tester.pumpWidget(_buildTestWidget(model));

      await tester.tap(find.text('Review My Settings'));
      await tester.pumpAndSettle();

      expect(find.text('Settings Page'), findsOneWidget);
    });
  });
}
