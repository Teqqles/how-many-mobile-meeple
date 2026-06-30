@Tags(['widget'])
library;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_many_mobile_meeple/api/http_retry_client.dart';
import 'package:how_many_mobile_meeple/api/plays_service.dart';
import 'package:how_many_mobile_meeple/favourites/favourites_service.dart';
import 'package:how_many_mobile_meeple/favourites/ignored_games_service.dart';
import 'package:how_many_mobile_meeple/model/item.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/platform/web_or_tablet/enhanced_list_games_display.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../helpers/mock_api_client.dart';

Map<String, dynamic> _gameJson(int id, String name,
    {double rating = 7.5, int playtime = 60, double weight = 2.5}) {
  return {
    'id': id,
    'name': name,
    'maxplayers': 4,
    'minplayers': 2,
    'maxplaytime': playtime,
    'image': 'https://example.com/$id.jpg',
    'stats': {'average': rating, 'averageweight': weight},
  };
}

Widget _buildTestApp(AppModel model) {
  return ChangeNotifierProvider<AppModel>.value(
    value: model,
    child: MaterialApp(
      home: EnhancedListGamesDisplayPage(),
    ),
  );
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

  group('EnhancedListGamesDisplayPage', () {
    testWidgets('shows loading while services initialise', (tester) async {
      HttpRetryClient.setTestClient(mockApiClient(
        collection: [_gameJson(1, 'Wingspan')],
      ));

      final model = AppModel();
      model.hasLoadedPersistedData = true;
      model.items.itemList.add(Item('testuser', itemType: ItemType.collection));

      await tester.pumpWidget(_buildTestApp(model));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('renders game list after data loads', (tester) async {
      HttpRetryClient.setTestClient(mockApiClient(
        collection: [
          _gameJson(1, 'Wingspan'),
          _gameJson(2, 'Catan'),
        ],
      ));

      final model = AppModel();
      model.hasLoadedPersistedData = true;
      model.items.itemList.add(Item('testuser', itemType: ItemType.collection));

      await tester.pumpWidget(_buildTestApp(model));
      await tester.pumpAndSettle();

      expect(find.text('Wingspan'), findsOneWidget);
      expect(find.text('Catan'), findsOneWidget);
    });

    testWidgets('shows exhausted state when all games ignored', (tester) async {
      SharedPreferences.setMockInitialValues({
        'ignored_games': jsonEncode([
          {'id': 1, 'name': 'Wingspan'},
          {'id': 2, 'name': 'Catan'},
        ])
      });

      HttpRetryClient.setTestClient(mockApiClient(
        collection: [
          _gameJson(1, 'Wingspan'),
          _gameJson(2, 'Catan'),
        ],
      ));

      final model = AppModel();
      model.hasLoadedPersistedData = true;
      model.items.itemList.add(Item('testuser', itemType: ItemType.collection));

      await tester.pumpWidget(_buildTestApp(model));
      await tester.pumpAndSettle();

      expect(find.text('All games are currently hidden'), findsOneWidget);
    });

    testWidgets('include ignored games button resets filter', (tester) async {
      SharedPreferences.setMockInitialValues({
        'ignored_games': jsonEncode([
          {'id': 1, 'name': 'Wingspan'},
          {'id': 2, 'name': 'Catan'},
        ])
      });

      HttpRetryClient.setTestClient(mockApiClient(
        collection: [
          _gameJson(1, 'Wingspan'),
          _gameJson(2, 'Catan'),
        ],
      ));

      final model = AppModel();
      model.hasLoadedPersistedData = true;
      model.items.itemList.add(Item('testuser', itemType: ItemType.collection));

      await tester.pumpWidget(_buildTestApp(model));
      await tester.pumpAndSettle();

      expect(find.text('All games are currently hidden'), findsOneWidget);

      await tester.tap(find.text('Include ignored games'));
      await tester.pumpAndSettle();

      expect(find.text('Wingspan'), findsOneWidget);
      expect(find.text('Catan'), findsOneWidget);
    });

    testWidgets('shows no sources message when items empty', (tester) async {
      HttpRetryClient.setTestClient(mockApiClient());

      final model = AppModel();
      model.hasLoadedPersistedData = true;

      await tester.pumpWidget(_buildTestApp(model));
      await tester.pumpAndSettle();

      expect(find.text('No game sources set up yet'), findsOneWidget);
    });

    testWidgets('name sort header is present', (tester) async {
      HttpRetryClient.setTestClient(mockApiClient(
        collection: [
          _gameJson(1, 'Wingspan'),
          _gameJson(2, 'Catan'),
        ],
      ));

      final model = AppModel();
      model.hasLoadedPersistedData = true;
      model.items.itemList.add(Item('testuser', itemType: ItemType.collection));

      await tester.pumpWidget(_buildTestApp(model));
      await tester.pumpAndSettle();

      expect(find.text('Name'), findsOneWidget);
    });
  });
}
