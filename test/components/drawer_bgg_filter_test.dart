@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_many_mobile_meeple/components/drawer_bgg_filter.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/model/setting.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _buildTestApp(AppModel model, Setting setting,
    {String title = 'Test Filter', int index = 0}) {
  return ChangeNotifierProvider<AppModel>.value(
    value: model,
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) =>
              DrawerBggFilter(title, setting, model, context, index: index),
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

  group('DrawerBggFilter', () {
    testWidgets('renders filter title text', (tester) async {
      final model = AppModel();
      final setting = Setting('test_filter', value: false);

      await tester
          .pumpWidget(_buildTestApp(model, setting, title: 'My Filter'));
      await tester.pump();

      expect(find.text('My Filter'), findsOneWidget);
    });

    testWidgets('switch shows correct initial value when false',
        (tester) async {
      final model = AppModel();
      final setting = Setting('test_filter', value: false);

      await tester.pumpWidget(_buildTestApp(model, setting));
      await tester.pump();

      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, isFalse);
    });

    testWidgets('switch shows correct initial value when true', (tester) async {
      final model = AppModel();
      final setting = Setting('test_filter', value: true);

      await tester.pumpWidget(_buildTestApp(model, setting));
      await tester.pump();

      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, isTrue);
    });

    testWidgets('toggle updates setting value and enabled', (tester) async {
      final model = AppModel();
      final setting = Setting('test_filter', value: false, enabled: false);

      await tester.pumpWidget(_buildTestApp(model, setting));
      await tester.pump();

      await tester.tap(find.byType(Switch));
      await tester.pump();

      expect(setting.value, isTrue);
      expect(setting.enabled, isTrue);
    });

    testWidgets('renders without error at different index values',
        (tester) async {
      final model = AppModel();
      final setting = Setting('test_filter', value: false);

      await tester.pumpWidget(_buildTestApp(model, setting, index: 0));
      await tester.pump();
      expect(find.text('Test Filter'), findsOneWidget);

      await tester.pumpWidget(_buildTestApp(model, setting, index: 1));
      await tester.pump();
      expect(find.text('Test Filter'), findsOneWidget);
    });
  });
}
