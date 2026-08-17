@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:how_many_mobile_meeple/api/http_retry_client.dart';
import 'package:how_many_mobile_meeple/api/plays_service.dart';
import 'package:how_many_mobile_meeple/model/item.dart';
import 'package:how_many_mobile_meeple/model/items.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/mock_api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PlaysService.clearCache();
    HttpRetryClient.setDelayFunction((_) async {});
    HttpRetryClient.setTestClient(mockApiClient());
  });

  tearDown(() {
    HttpRetryClient.resetTestClient();
    HttpRetryClient.resetDelayFunction();
    PlaysService.clearCache();
  });

  group('AppModel.primaryPlayer', () {
    test('defaults to null when no collections added', () {
      final model = AppModel();
      expect(model.primaryPlayer, isNull);
    });

    test('auto-sets to first collection item added', () async {
      final model = AppModel();
      await model.addItem(Item('teqqles'));

      expect(model.primaryPlayer, 'teqqles');
    });

    test('does not auto-set for geekList items', () async {
      final model = AppModel();
      await model.addItem(Item('12345', itemType: ItemType.geekList));

      expect(model.primaryPlayer, isNull);
    });

    test('does not auto-set for hotList items', () async {
      final model = AppModel();
      await model.addItem(Item('trending', itemType: ItemType.hotList));

      expect(model.primaryPlayer, isNull);
    });

    test(
      'does not override existing primary player when adding more collections',
      () async {
        final model = AppModel();
        await model.addItem(Item('teqqles'));
        await model.addItem(Item('otheruser'));

        expect(model.primaryPlayer, 'teqqles');
      },
    );

    test('can be set explicitly', () async {
      final model = AppModel();
      await model.addItem(Item('teqqles'));
      await model.addItem(Item('otheruser'));

      model.primaryPlayer = 'otheruser';

      expect(model.primaryPlayer, 'otheruser');
    });

    test(
      'resets to next collection when primary player item is deleted',
      () async {
        final model = AppModel();
        await model.addItem(Item('teqqles'));
        await model.addItem(Item('otheruser'));

        expect(model.primaryPlayer, 'teqqles');

        await model.deleteItem(Item('teqqles'));

        expect(model.primaryPlayer, 'otheruser');
      },
    );

    test('resets to null when last collection item is deleted', () async {
      final model = AppModel();
      await model.addItem(Item('teqqles'));

      expect(model.primaryPlayer, 'teqqles');

      await model.deleteItem(Item('teqqles'));

      expect(model.primaryPlayer, isNull);
    });

    test('is not affected by deleting non-primary collection items', () async {
      final model = AppModel();
      await model.addItem(Item('teqqles'));
      await model.addItem(Item('otheruser'));

      await model.deleteItem(Item('otheruser'));

      expect(model.primaryPlayer, 'teqqles');
    });

    test('persists across store operations', () async {
      final model = AppModel();
      await model.addItem(Item('teqqles'));

      expect(model.primaryPlayer, 'teqqles');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('primary_player'), 'teqqles');
    });

    test('loads persisted primary player on loadStoredData', () async {
      SharedPreferences.setMockInitialValues({
        'primary_player': 'saveduser',
        'bgg-item-0': '{"name":"saveduser","item_type":{"name":"collection"}}',
      });

      final model = AppModel();
      await model.loadStoredData();

      expect(model.primaryPlayer, 'saveduser');
    });

    test('sets primary player to first collection on refresh when stored value '
        'is missing', () async {
      // A stored collection with no persisted primary player (e.g. cleared in a
      // prior session) must still surface a primary player on refresh.
      SharedPreferences.setMockInitialValues({
        'bgg-item-0': '{"name":"firstuser","item_type":{"name":"collection"}}',
        'bgg-item-1': '{"name":"seconduser","item_type":{"name":"collection"}}',
      });

      final model = AppModel();
      await model.loadStoredData();

      expect(model.primaryPlayer, 'firstuser');
    });

    test('resets primary player to first collection on refresh when stored '
        'value is no longer in the list', () async {
      SharedPreferences.setMockInitialValues({
        'primary_player': 'goneuser',
        'bgg-item-0': '{"name":"firstuser","item_type":{"name":"collection"}}',
      });

      final model = AppModel();
      await model.loadStoredData();

      expect(model.primaryPlayer, 'firstuser');
    });

    test('notifies listeners when primary player changes', () async {
      final model = AppModel();
      await model.addItem(Item('teqqles'));
      await model.addItem(Item('otheruser'));

      int notifyCount = 0;
      model.addListener(() => notifyCount++);

      model.primaryPlayer = 'otheruser';

      expect(notifyCount, 1);
    });

    test('does not notify if setting same primary player', () async {
      final model = AppModel();
      await model.addItem(Item('teqqles'));

      int notifyCount = 0;
      model.addListener(() => notifyCount++);

      model.primaryPlayer = 'teqqles';

      expect(notifyCount, 0);
    });
  });

  group('AppModel.replaceItems primary player reconciliation', () {
    test(
      'switches primary player when items are replaced with a new collection',
      () async {
        final model = AppModel();
        await model.addItem(Item('olduser'));
        expect(model.primaryPlayer, 'olduser');

        await model.replaceItems(Items([Item('newuser')]));

        expect(model.primaryPlayer, 'newuser');
      },
    );

    test(
      'keeps primary player when it is still among the replaced items',
      () async {
        final model = AppModel();
        await model.addItem(Item('teqqles'));

        await model.replaceItems(Items([Item('teqqles'), Item('otheruser')]));

        expect(model.primaryPlayer, 'teqqles');
      },
    );

    test(
      'clears primary player when no collections remain after replace',
      () async {
        final model = AppModel();
        await model.addItem(Item('olduser'));

        await model.replaceItems(
          Items([Item('hot', itemType: ItemType.hotList)]),
        );

        expect(model.primaryPlayer, isNull);
      },
    );

    test('replacing collection reloads plays for the new primary player', () async {
      final capturedPaths = <String>[];
      HttpRetryClient.setTestClient(
        mockApiClient(onRequest: (r) => capturedPaths.add(r.url.path)),
      );

      final model = AppModel();
      await model.addItem(Item('olduser'));
      await Future.delayed(Duration.zero);
      capturedPaths.clear();

      await model.replaceItems(Items([Item('newuser')]));
      await Future.delayed(Duration.zero);

      // Switching collections must fetch plays/collection for the new player so
      // shelf of shame / play history don't stick to the old collection.
      expect(capturedPaths, contains('/plays/newuser'));
      expect(capturedPaths, contains('/collection/newuser'));
      expect(capturedPaths, isNot(contains('/plays/olduser')));
    });
  });
}
