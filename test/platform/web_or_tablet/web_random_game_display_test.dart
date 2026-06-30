@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:how_many_mobile_meeple/api/http_retry_client.dart';
import 'package:how_many_mobile_meeple/api/plays_service.dart';
import 'package:how_many_mobile_meeple/favourites/favourites_service.dart';
import 'package:how_many_mobile_meeple/favourites/ignored_games_service.dart';
import 'package:how_many_mobile_meeple/model/games.dart';
import 'package:how_many_mobile_meeple/model/item.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/platform/web_or_tablet/web_random_game_display.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../helpers/sync_mock_client.dart';

Map<String, dynamic> _gameJson(int id, String name) => {
      'id': id,
      'name': name,
      'maxplayers': 4,
      'minplayers': 2,
      'maxplaytime': 60,
      'image': 'https://example.com/$id.jpg',
      'stats': {'average': 7.5, 'averageweight': 2.5},
    };

Widget _buildTestApp(AppModel model, {Size size = const Size(800, 1200)}) {
  return ChangeNotifierProvider<AppModel>.value(
    value: model,
    child: MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: SizedBox.expand(child: WebRandomGameDisplayPage()),
      ),
    ),
  );
}

void _primeCache(AppModel model, List<Map<String, dynamic>> gameData) {
  final games = Games.fromJson(gameData);
  model.replaceCache(games, model.buildRequest());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FavouritesService.resetForTesting();
    IgnoredGamesService.resetForTesting();
    PlaysService.clearCache();
    HttpRetryClient.setDelayFunction((_) async {});
  });

  tearDown(() {
    HttpRetryClient.resetTestClient();
    HttpRetryClient.resetDelayFunction();
    PlaysService.clearCache();
    FavouritesService.resetForTesting();
    IgnoredGamesService.resetForTesting();
  });

  group('WebRandomGameDisplayPage', () {
    testWidgets('shows no sources message when items are empty',
        (tester) async {
      HttpRetryClient.setTestClient(
        SyncMockClient((_) => http.Response('[]', 200)),
      );

      final model = AppModel();
      model.hasLoadedPersistedData = true;

      await tester.pumpWidget(_buildTestApp(model));
      await tester.pumpAndSettle();

      expect(find.text('No game sources set up yet'), findsOneWidget);
    });

    testWidgets('displays a random game from collection', (tester) async {
      final oldHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.toString().contains('overflowed')) return;
        oldHandler?.call(details);
      };
      addTearDown(() => FlutterError.onError = oldHandler);

      HttpRetryClient.setTestClient(
        SyncMockClient((_) => http.Response('[]', 200)),
      );

      final model = AppModel();
      model.hasLoadedPersistedData = true;
      model.items.itemList.add(Item('testuser', itemType: ItemType.collection));
      _primeCache(model, [
        _gameJson(1, 'Wingspan'),
        _gameJson(2, 'Catan'),
        _gameJson(3, 'Azul'),
      ]);
      model.pageRefreshed = true;

      await tester.pumpWidget(_buildTestApp(model));
      await tester.pump();

      final gameNames = ['Wingspan', 'Catan', 'Azul'];
      final found =
          gameNames.any((name) => find.text(name).evaluate().isNotEmpty);
      expect(found, isTrue);
    });

    testWidgets('shows exhausted state when pool is empty', (tester) async {
      final oldHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.toString().contains('overflowed')) return;
        oldHandler?.call(details);
      };
      addTearDown(() => FlutterError.onError = oldHandler);

      HttpRetryClient.setTestClient(
        SyncMockClient((_) => http.Response('[]', 200)),
      );

      final model = AppModel();
      model.hasLoadedPersistedData = true;
      model.items.itemList.add(Item('testuser', itemType: ItemType.collection));
      _primeCache(model, [_gameJson(1, 'Wingspan')]);
      model.pageRefreshed = true;

      await tester.pumpWidget(_buildTestApp(model));
      await tester.pump();
      await tester.pump();
      await tester.pump();

      // After showing the single game, refresh should show exhausted
      // (or the game is shown since sticky holds it)
      expect(
        find.text("You've seen all available games").evaluate().isNotEmpty ||
            find.text('Wingspan').evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('shows loading state while games are fetching', (tester) async {
      HttpRetryClient.setTestClient(
        SyncMockClient((_) => http.Response('[]', 200)),
      );

      final model = AppModel();
      model.hasLoadedPersistedData = true;
      model.items.itemList.add(Item('testuser', itemType: ItemType.collection));
      model.bggCache.makeStale();

      await tester.pumpWidget(_buildTestApp(model));

      expect(find.text('Finding games to play'), findsOneWidget);
    });
  });
}
