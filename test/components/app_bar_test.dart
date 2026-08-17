@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_many_mobile_meeple/how_many_meeple_app_bar.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _buildTestApp({
  bool isHomePage = true,
  bool hasSaveDialog = false,
  String? helpSection,
  AppModel? model,
  Map<String, WidgetBuilder>? routes,
}) {
  final appModel = model ?? AppModel();
  return ChangeNotifierProvider<AppModel>.value(
    value: appModel,
    child: MaterialApp(
      routes: routes ?? const {},
      home: Builder(
        builder: (context) => Scaffold(
          appBar: HowManyMeepleAppBar(
            'Test Subtitle',
            context: context,
            isHomePage: isHomePage,
            hasSaveDialog: hasSaveDialog,
            helpSection: helpSection,
            model: appModel,
          ),
          endDrawer: const Drawer(child: Text('Settings Drawer')),
          drawer: const Drawer(child: Text('Feature Drawer')),
          body: const Text('Body'),
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

  group('HowManyMeepleAppBar', () {
    testWidgets('does not show News button', (tester) async {
      await tester.pumpWidget(_buildTestApp());

      expect(find.byTooltip('Board Game News'), findsNothing);
    });

    testWidgets('does not show Quick Pick button', (tester) async {
      await tester.pumpWidget(_buildTestApp());

      expect(find.byTooltip('Quick Pick'), findsNothing);
    });

    testWidgets('shows Favourites button', (tester) async {
      await tester.pumpWidget(_buildTestApp());

      expect(find.byTooltip('Favourites'), findsOneWidget);
    });

    testWidgets('shows Settings button', (tester) async {
      await tester.pumpWidget(_buildTestApp());

      expect(find.byTooltip('Settings'), findsOneWidget);
    });

    testWidgets('shows Help button', (tester) async {
      await tester.pumpWidget(_buildTestApp());

      expect(find.byTooltip('Help'), findsOneWidget);
    });

    testWidgets('Help button navigates to /help without a section', (
      tester,
    ) async {
      var pushedRoute = '';
      await tester.pumpWidget(
        _buildTestApp(
          routes: {
            '/help': (_) {
              pushedRoute = '/help';
              return const Scaffold(body: Text('Help Page'));
            },
          },
        ),
      );

      await tester.tap(find.byTooltip('Help'));
      await tester.pumpAndSettle();

      expect(pushedRoute, '/help');
    });

    testWidgets('Help button navigates to page section when set', (
      tester,
    ) async {
      var pushedRoute = '';
      await tester.pumpWidget(
        _buildTestApp(
          helpSection: 'list',
          routes: {
            '/help/list': (_) {
              pushedRoute = '/help/list';
              return const Scaffold(body: Text('Help Page'));
            },
          },
        ),
      );

      await tester.tap(find.byTooltip('Help'));
      await tester.pumpAndSettle();

      expect(pushedRoute, '/help/list');
    });

    testWidgets('shows Save button when hasSaveDialog is true', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(hasSaveDialog: true, model: AppModel()),
      );

      expect(find.byTooltip('Save Settings'), findsOneWidget);
    });

    testWidgets('does not show Save button when hasSaveDialog is false', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp(hasSaveDialog: false));

      expect(find.byTooltip('Save Settings'), findsNothing);
    });

    testWidgets('shows hamburger menu on home page', (tester) async {
      await tester.pumpWidget(_buildTestApp(isHomePage: true));

      expect(find.byIcon(Icons.menu), findsOneWidget);
    });

    testWidgets('shows both hamburger and back button on sub-pages', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp(isHomePage: false));

      expect(find.byIcon(Icons.menu), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('displays app title', (tester) async {
      await tester.pumpWidget(_buildTestApp());

      expect(find.text('How Many Meeple?'), findsOneWidget);
    });

    testWidgets('displays subtitle', (tester) async {
      await tester.pumpWidget(_buildTestApp());

      expect(find.text('Test Subtitle'), findsOneWidget);
    });
  });
}
