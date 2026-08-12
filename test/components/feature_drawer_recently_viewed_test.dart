@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_many_mobile_meeple/components/feature_drawer.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/recently_viewed/recently_viewed_game.dart';
import 'package:how_many_mobile_meeple/recently_viewed/recently_viewed_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _buildTestApp() {
  return ChangeNotifierProvider<AppModel>.value(
    value: AppModel(),
    child: MaterialApp(
      onGenerateRoute: (settings) => MaterialPageRoute(
        builder: (_) => Scaffold(body: Text('route: ${settings.name}')),
      ),
      home: Scaffold(
        drawer: const FeatureDrawer(),
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => Scaffold.of(context).openDrawer(),
            child: const Text('Open Drawer'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    RecentlyViewedService.resetForTesting();
    SharedPreferences.setMockInitialValues({});
  });

  group('FeatureDrawer recently viewed', () {
    testWidgets('hides the section when no games have been viewed',
        (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.tap(find.text('Open Drawer'));
      await tester.pumpAndSettle();

      expect(find.text('Recently Viewed'), findsNothing);
    });

    testWidgets('lists recently viewed games newest first', (tester) async {
      final service = await RecentlyViewedService.instance();
      service.add(RecentlyViewedGame(id: 1, name: 'Catan'));
      service.add(RecentlyViewedGame(id: 2, name: 'Wingspan'));

      await tester.pumpWidget(_buildTestApp());
      await tester.tap(find.text('Open Drawer'));
      await tester.pumpAndSettle();

      expect(find.text('Recently Viewed'), findsOneWidget);
      expect(find.text('Catan'), findsOneWidget);
      expect(find.text('Wingspan'), findsOneWidget);
    });

    testWidgets('tapping a game navigates to its detail route', (tester) async {
      final service = await RecentlyViewedService.instance();
      service.add(RecentlyViewedGame(id: 42, name: 'Root'));

      await tester.pumpWidget(_buildTestApp());
      await tester.tap(find.text('Open Drawer'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Root'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Root'));
      await tester.pumpAndSettle();

      expect(find.text('route: /game/42'), findsOneWidget);
    });
  });
}
