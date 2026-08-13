@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_many_mobile_meeple/components/theme_mode_control.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Mirrors production wiring: the drawer rebuilds the control inside a
// Consumer<AppModel>, so a setting change followed by notifyListeners() must
// rebuild the control with the new selection.
Widget _wrap(AppModel model) {
  return MaterialApp(
    home: ChangeNotifierProvider<AppModel>.value(
      value: model,
      child: Scaffold(
        body: SingleChildScrollView(
          child: Consumer<AppModel>(
            builder: (context, m, _) => ThemeModeControl(m),
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

  group('ThemeModeControl', () {
    testWidgets('renders System / Light / Dark options', (tester) async {
      await tester.pumpWidget(_wrap(AppModel()));
      await tester.pumpAndSettle();

      expect(find.text('System'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
    });

    testWidgets('selecting Dark updates the themeMode setting', (tester) async {
      final model = AppModel();
      await tester.pumpWidget(_wrap(model));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      expect(
          model.settings.setting(Settings.themeMode.name).getString(), 'dark');
    });

    testWidgets('rebuilds live with the new selection after a tap',
        (tester) async {
      final model = AppModel();
      await tester.pumpWidget(_wrap(model));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      final control = tester.widget<SegmentedButton<ThemeMode>>(
          find.byType(SegmentedButton<ThemeMode>));
      expect(control.selected, {ThemeMode.dark});
    });

    testWidgets('reflects the current setting as selected', (tester) async {
      final model = AppModel();
      model.settings.setting(Settings.themeMode.name).value = 'light';
      await tester.pumpWidget(_wrap(model));
      await tester.pumpAndSettle();

      final control = tester.widget<SegmentedButton<ThemeMode>>(
          find.byType(SegmentedButton<ThemeMode>));
      expect(control.selected, {ThemeMode.light});
    });
  });
}
