import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:how_many_mobile_meeple/api/http_retry_client.dart';
import 'package:how_many_mobile_meeple/api/plays_service.dart';
import 'package:how_many_mobile_meeple/model/item.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PlaysService.clearCache();
    HttpRetryClient.setDelayFunction((_) async {});
    HttpRetryClient.setTestClient(
      http_testing.MockClient((request) async => http.Response('[]', 200)),
    );
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
    });

    test('can be set explicitly', () async {
      final model = AppModel();
      await model.addItem(Item('teqqles'));
      await model.addItem(Item('otheruser'));

      model.primaryPlayer = 'otheruser';

      expect(model.primaryPlayer, 'otheruser');
    });

    test('resets to next collection when primary player item is deleted',
        () async {
      final model = AppModel();
      await model.addItem(Item('teqqles'));
      await model.addItem(Item('otheruser'));

      expect(model.primaryPlayer, 'teqqles');

      await model.deleteItem(Item('teqqles'));

      expect(model.primaryPlayer, 'otheruser');
    });

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
        'item_0': '{"name":"saveduser","item_type":{"name":"collection"}}',
      });

      final model = AppModel();
      await model.loadStoredData();

      expect(model.primaryPlayer, 'saveduser');
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
}
