@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/model/item.dart';
import 'package:how_many_mobile_meeple/network_content_widget.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TestNetworkWidget extends NetworkWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: loadNetworkContent(
        (context, model) => const Text('Game content loaded'),
      ),
    );
  }
}

Widget _buildTestWidget(AppModel model) {
  return ChangeNotifierProvider<AppModel>.value(
    value: model,
    child: MaterialApp(home: _TestNetworkWidget()),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('NetworkWidget', () {
    group('error messages', () {
      test('errorForItems returns hot list message when only hot items', () {
        final model = AppModel();
        model.items.itemList.add(Item('hot', itemType: ItemType.hotList));

        expect(
          NetworkWidget.errorForItems(model),
          'Unable to load trending games - BGG may be unavailable',
        );
      });

      test('errorForItems returns collection message when only BGG items', () {
        final model = AppModel();
        model.items.itemList
            .add(Item('user123', itemType: ItemType.collection));

        expect(
          NetworkWidget.errorForItems(model),
          'One or more of your collections or geeklists cannot be loaded',
        );
      });

      test('errorForItems returns generic message when mixed items', () {
        final model = AppModel();
        model.items.itemList.add(Item('hot', itemType: ItemType.hotList));
        model.items.itemList
            .add(Item('user123', itemType: ItemType.collection));

        expect(
          NetworkWidget.errorForItems(model),
          NetworkWidget.pageErrorOneOrMoreItemsInvalid,
        );
      });
    });

    group('no sources state', () {
      testWidgets('shows empty state when items are empty and data loaded',
          (tester) async {
        final model = AppModel();
        model.hasLoadedPersistedData = true;

        await tester.pumpWidget(_buildTestWidget(model));
        await tester.pumpAndSettle();

        expect(find.text('No game sources set up yet'), findsOneWidget);
        expect(
          find.text('Add a BGG collection or geeklist to get started'),
          findsOneWidget,
        );
        expect(find.text('Go to Home'), findsOneWidget);
      });
    });

    group('loading state', () {
      testWidgets('shows finding games text during initial load',
          (tester) async {
        final model = AppModel();

        await tester.pumpWidget(_buildTestWidget(model));

        expect(find.text(NetworkWidget.findingGames), findsOneWidget);
      });
    });

    group('static constants', () {
      test('has expected error messages', () {
        expect(
          NetworkWidget.pageErrorNoItemsSupplied,
          'You must provide at least one source of games',
        );
        expect(
          NetworkWidget.pageErrorNoGamesAvailable,
          contains('filters have eliminated all games'),
        );
      });
    });
  });
}
