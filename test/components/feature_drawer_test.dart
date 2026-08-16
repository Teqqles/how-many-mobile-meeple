@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:how_many_mobile_meeple/api/http_retry_client.dart';
import 'package:how_many_mobile_meeple/components/feature_drawer.dart';
import 'package:how_many_mobile_meeple/model/item.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/sync_mock_client.dart';

Widget _buildTestApp({AppModel? model}) {
  final appModel = model ?? AppModel();
  addTearDown(appModel.dispose);
  return ChangeNotifierProvider<AppModel>.value(
    value: appModel,
    child: MaterialApp(
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
    SharedPreferences.setMockInitialValues({});
    // Adding a collection seeds filter defaults from analytics; a 404 resolves
    // that fetch synchronously to a final result, so no retry timer is armed.
    HttpRetryClient.setTestClient(
        SyncMockClient((_) => http.Response('', 404)));
  });
  tearDown(HttpRetryClient.resetTestClient);

  group('FeatureDrawer', () {
    testWidgets('displays Play section header', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.tap(find.text('Open Drawer'));
      await tester.pumpAndSettle();

      expect(find.text('Play'), findsOneWidget);
    });

    testWidgets('displays Discover section header', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.tap(find.text('Open Drawer'));
      await tester.pumpAndSettle();

      expect(find.text('Discover'), findsOneWidget);
    });

    testWidgets('displays My Games section header', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.tap(find.text('Open Drawer'));
      await tester.pumpAndSettle();

      expect(find.text('My Games'), findsOneWidget);
    });

    testWidgets('displays Quick Pick in Play section', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.tap(find.text('Open Drawer'));
      await tester.pumpAndSettle();

      expect(find.text('Quick Pick'), findsOneWidget);
    });

    testWidgets('displays Random Game in Play section', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.tap(find.text('Open Drawer'));
      await tester.pumpAndSettle();

      expect(find.text('Random Game'), findsOneWidget);
    });

    testWidgets('displays View List in Play section', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.tap(find.text('Open Drawer'));
      await tester.pumpAndSettle();

      expect(find.text('View List'), findsOneWidget);
    });

    testWidgets('displays Shelf of Shame in Discover section', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.tap(find.text('Open Drawer'));
      await tester.pumpAndSettle();

      expect(find.text('Shelf of Shame'), findsOneWidget);
    });

    testWidgets('displays Collection Insights in Discover section',
        (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.tap(find.text('Open Drawer'));
      await tester.pumpAndSettle();

      expect(find.text('Collection Insights'), findsOneWidget);
    });

    testWidgets(
        'shows collection-specific snackbar when tapping Collection Insights without collection',
        (tester) async {
      final model = AppModel();
      await model.addItem(Item('trending', itemType: ItemType.hotList));

      await tester.pumpWidget(_buildTestApp(model: model));
      await tester.tap(find.text('Open Drawer'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Collection Insights'));
      await tester.pumpAndSettle();

      expect(find.text('Add a BGG collection first'), findsOneWidget);
    });

    testWidgets('displays Favourites in My Games section', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.tap(find.text('Open Drawer'));
      await tester.pumpAndSettle();

      expect(find.text('Favourites'), findsOneWidget);
    });

    testWidgets('displays Ignored Games in My Games section', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.tap(find.text('Open Drawer'));
      await tester.pumpAndSettle();

      expect(find.text('Ignored Games'), findsOneWidget);
    });

    testWidgets('displays Board Game News in My Games section', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.tap(find.text('Open Drawer'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Board Game News'), 100,
          scrollable: find.byType(Scrollable).first);
      expect(find.text('Board Game News'), findsOneWidget);
    });

    testWidgets('shows snackbar when tapping Quick Pick with no sources',
        (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.tap(find.text('Open Drawer'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Quick Pick'));
      await tester.pumpAndSettle();

      expect(find.text('Add a source first'), findsOneWidget);
    });

    testWidgets('shows snackbar when tapping Random Game with no sources',
        (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.tap(find.text('Open Drawer'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Random Game'));
      await tester.pumpAndSettle();

      expect(find.text('Add a source first'), findsOneWidget);
    });

    testWidgets('shows snackbar when tapping View List with no sources',
        (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.tap(find.text('Open Drawer'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('View List'));
      await tester.pumpAndSettle();

      expect(find.text('Add a source first'), findsOneWidget);
    });

    testWidgets(
        'shows collection-specific snackbar when tapping Shelf of Shame without collection',
        (tester) async {
      final model = AppModel();
      await model.addItem(Item('trending', itemType: ItemType.hotList));

      await tester.pumpWidget(_buildTestApp(model: model));
      await tester.tap(find.text('Open Drawer'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Shelf of Shame'));
      await tester.pumpAndSettle();

      expect(find.text('Add a BGG collection first'), findsOneWidget);
    });

    testWidgets('Play items are enabled when sources exist', (tester) async {
      final model = AppModel();
      await model.addItem(Item('testuser'));

      await tester.pumpWidget(_buildTestApp(model: model));
      await tester.tap(find.text('Open Drawer'));
      await tester.pumpAndSettle();

      final quickPickTile = tester.widget<ListTile>(find.ancestor(
        of: find.text('Quick Pick'),
        matching: find.byType(ListTile),
      ));
      expect(quickPickTile.onTap, isNotNull);
    });
  });
}
