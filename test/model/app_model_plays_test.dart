@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:how_many_mobile_meeple/api/http_retry_client.dart';
import 'package:how_many_mobile_meeple/api/plays_service.dart';
import 'package:how_many_mobile_meeple/model/item.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/mock_api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PlaysService.clearCache();
    HttpRetryClient.setDelayFunction((_) => Future.value());
  });

  tearDown(() {
    HttpRetryClient.resetTestClient();
    HttpRetryClient.resetDelayFunction();
    PlaysService.clearCache();
  });

  group('AppModel plays integration', () {
    test('getPlayCount returns 0 when plays not loaded', () {
      final model = AppModel();
      expect(model.getPlayCount(123), 0);
    });

    test('isUnplayed returns true when plays not loaded', () {
      final model = AppModel();
      expect(model.isUnplayed(123), isTrue);
    });

    test('loadPlays fetches and stores play data', () async {
      HttpRetryClient.setTestClient(mockApiClient(plays: [
        {'game_id': 1, 'game_name': 'Wingspan', 'total_plays': 5},
        {'game_id': 2, 'game_name': 'Catan', 'total_plays': 0},
      ]));

      final model = AppModel();
      await model.addItem(Item('testuser'));
      await model.loadPlays();

      expect(model.getPlayCount(1), 5);
      expect(model.getPlayCount(2), 0);
    });

    test('getPlayCount returns correct count after loading', () async {
      HttpRetryClient.setTestClient(mockApiClient(plays: [
        {'game_id': 42, 'game_name': 'Azul', 'total_plays': 7},
      ]));

      final model = AppModel();
      await model.addItem(Item('testuser'));
      await model.loadPlays();

      expect(model.getPlayCount(42), 7);
    });

    test('getPlayCount returns 0 for games not in plays data', () async {
      HttpRetryClient.setTestClient(mockApiClient(plays: [
        {'game_id': 1, 'game_name': 'Wingspan', 'total_plays': 5},
      ]));

      final model = AppModel();
      await model.addItem(Item('testuser'));
      await model.loadPlays();

      expect(model.getPlayCount(999), 0);
    });

    test('isUnplayed returns true for games with 0 plays', () async {
      HttpRetryClient.setTestClient(mockApiClient(plays: [
        {'game_id': 1, 'game_name': 'Wingspan', 'total_plays': 5},
        {'game_id': 2, 'game_name': 'Catan', 'total_plays': 0},
      ]));

      final model = AppModel();
      await model.addItem(Item('testuser'));
      await model.loadPlays();

      expect(model.isUnplayed(2), isTrue);
    });

    test('isUnplayed returns true for games not in plays data', () async {
      HttpRetryClient.setTestClient(mockApiClient(plays: [
        {'game_id': 1, 'game_name': 'Wingspan', 'total_plays': 5},
      ]));

      final model = AppModel();
      await model.addItem(Item('testuser'));
      await model.loadPlays();

      expect(model.isUnplayed(999), isTrue);
    });

    test('isUnplayed returns false for games with plays', () async {
      HttpRetryClient.setTestClient(mockApiClient(plays: [
        {'game_id': 1, 'game_name': 'Wingspan', 'total_plays': 5},
      ]));

      final model = AppModel();
      await model.addItem(Item('testuser'));
      await model.loadPlays();

      expect(model.isUnplayed(1), isFalse);
    });

    test('loadPlays does nothing when no primary player set', () async {
      int callCount = 0;
      HttpRetryClient.setTestClient(
          mockApiClient(onRequest: (_) => callCount++));

      final model = AppModel();
      await model.addItem(Item('trending', itemType: ItemType.hotList));
      await model.loadPlays();

      expect(callCount, 0);
    });

    test('loadPlays uses primary player username', () async {
      final capturedPaths = <String>[];
      HttpRetryClient.setTestClient(
          mockApiClient(onRequest: (r) => capturedPaths.add(r.url.path)));

      final model = AppModel();
      await model.addItem(Item('teqqles'));
      await model.loadPlays();

      expect(capturedPaths, contains('/plays/teqqles'));
      expect(capturedPaths, contains('/collection/teqqles'));
    });

    test('isInCollection returns true for games in collection', () async {
      HttpRetryClient.setTestClient(mockApiClient(collection: [
        {
          'id': 1,
          'name': 'Wingspan',
          'minplayers': 1,
          'maxplayers': 5,
          'maxplaytime': 70,
          'image': null,
          'thumbnail': null,
          'stats': {'average': 8.0, 'averageweight': 2.5},
        },
      ]));

      final model = AppModel();
      await model.addItem(Item('testuser'));
      await model.loadPlays();

      expect(model.isInCollection(1), isTrue);
      expect(model.isInCollection(999), isFalse);
    });

    test('playsLoaded is false initially', () {
      final model = AppModel();
      expect(model.playsLoaded, isFalse);
    });

    test('playsLoaded is true after successful load', () async {
      HttpRetryClient.setTestClient(mockApiClient());

      final model = AppModel();
      await model.addItem(Item('testuser'));
      await model.loadPlays();

      expect(model.playsLoaded, isTrue);
    });

    test('notifies listeners when plays load completes', () async {
      HttpRetryClient.setTestClient(mockApiClient());

      final model = AppModel();
      await model.addItem(Item('testuser'));

      int notifyCount = 0;
      model.addListener(() => notifyCount++);

      await model.loadPlays();

      expect(notifyCount, greaterThan(0));
    });

    test('loadStoredData triggers loadPlays when primary player exists',
        () async {
      final capturedPaths = <String>[];
      HttpRetryClient.setTestClient(
          mockApiClient(onRequest: (r) => capturedPaths.add(r.url.path)));

      SharedPreferences.setMockInitialValues({
        'primary_player': 'storeduser',
        'item_0': '{"name":"storeduser","item_type":{"name":"collection"}}',
      });

      final model = AppModel();
      await model.loadStoredData();
      await Future.delayed(Duration.zero);

      expect(capturedPaths, contains('/plays/storeduser'));
      expect(capturedPaths, contains('/collection/storeduser'));
    });

    test('primaryPlayer setter triggers loadPlays', () async {
      final capturedPaths = <String>[];
      HttpRetryClient.setTestClient(
          mockApiClient(onRequest: (r) => capturedPaths.add(r.url.path)));

      final model = AppModel();
      await model.addItem(Item('user1'));
      await model.addItem(Item('user2'));
      capturedPaths.clear();

      model.primaryPlayer = 'user2';
      await Future.delayed(Duration.zero);

      expect(capturedPaths, contains('/plays/user2'));
      expect(capturedPaths, contains('/collection/user2'));
    });

    test('primaryPlayer setter resets plays state', () async {
      HttpRetryClient.setTestClient(mockApiClient(plays: [
        {'game_id': 1, 'game_name': 'Wingspan', 'total_plays': 5},
      ]));

      final model = AppModel();
      await model.addItem(Item('user1'));
      await model.addItem(Item('user2'));
      await model.loadPlays();
      expect(model.playsLoaded, isTrue);
      expect(model.getPlayCount(1), 5);

      HttpRetryClient.setTestClient(mockApiClient());
      model.primaryPlayer = 'user2';

      expect(model.playsLoaded, isFalse);
      expect(model.getPlayCount(1), 0);

      await model.loadPlays();
    });
  });
}
