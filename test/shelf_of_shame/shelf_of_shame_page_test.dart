@Tags(['widget'])
library;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:how_many_mobile_meeple/api/http_retry_client.dart';
import 'package:how_many_mobile_meeple/api/plays_service.dart';
import 'package:how_many_mobile_meeple/model/item.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/shelf_of_shame/shelf_of_shame_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/mock_api_client.dart';
import '../helpers/sync_mock_client.dart';

Widget _buildTestApp(AppModel model) {
  return ChangeNotifierProvider<AppModel>.value(
    value: model,
    child: MaterialApp(
      home: const ShelfOfShamePage(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PlaysService.clearCache();
    HttpRetryClient.setDelayFunction((_) async {});
  });

  tearDown(() {
    HttpRetryClient.resetTestClient();
    HttpRetryClient.resetDelayFunction();
    PlaysService.clearCache();
  });

  group('ShelfOfShamePage', () {
    testWidgets('shows no collection message when no collection added',
        (tester) async {
      HttpRetryClient.setTestClient(mockApiClient());

      final model = AppModel();
      await model.addItem(Item('trending', itemType: ItemType.hotList));

      await tester.pumpWidget(_buildTestApp(model));
      await tester.pumpAndSettle();

      expect(find.text('No collection added'), findsOneWidget);
      expect(find.textContaining('requires a BGG collection'), findsOneWidget);
    });

    testWidgets(
        'shows no primary player message when collection exists but no player set',
        (tester) async {
      HttpRetryClient.setTestClient(mockApiClient());

      final model = AppModel();
      await model.addItem(Item('testuser'));
      model.primaryPlayer = null;

      await tester.pumpWidget(_buildTestApp(model));
      await tester.pumpAndSettle();

      expect(find.text('No primary player set'), findsOneWidget);
      expect(find.textContaining('crown icon'), findsOneWidget);
    });

    testWidgets('shows loading indicator initially', (tester) async {
      HttpRetryClient.setTestClient(mockApiClient(
        collection: [],
        plays: [],
      ));

      final model = AppModel();
      await model.addItem(Item('testuser'));

      await tester.pumpWidget(_buildTestApp(model));

      expect(find.byType(SpinKitCubeGrid), findsOneWidget);
    });

    testWidgets('shows collection banner with primary player name',
        (tester) async {
      HttpRetryClient.setTestClient(mockApiClient(
        collection: [
          _gameJson(1, 'Wingspan'),
          _gameJson(2, 'Catan'),
        ],
        plays: [
          {'game_id': 1, 'game_name': 'Wingspan', 'total_plays': 5},
        ],
      ));

      final model = AppModel();
      await model.addItem(Item('teqqles'));

      await tester.pumpWidget(_buildTestApp(model));
      await tester.pumpAndSettle();

      expect(find.textContaining("teqqles's collection"), findsOneWidget);
    });

    testWidgets('shows only unplayed games from full collection',
        (tester) async {
      HttpRetryClient.setTestClient(mockApiClient(
        collection: [
          _gameJson(1, 'Wingspan'),
          _gameJson(2, 'Catan'),
          _gameJson(3, 'Azul'),
        ],
        plays: [
          {'game_id': 1, 'game_name': 'Wingspan', 'total_plays': 5},
          {'game_id': 2, 'game_name': 'Catan', 'total_plays': 0},
        ],
      ));

      final model = AppModel();
      await model.addItem(Item('testuser'));

      await tester.pumpWidget(_buildTestApp(model));
      await tester.pumpAndSettle();

      expect(find.text('Catan'), findsOneWidget);
      expect(find.text('Azul'), findsOneWidget);
      expect(find.text('Wingspan'), findsNothing);
    });

    testWidgets('shows unplayed count in banner', (tester) async {
      HttpRetryClient.setTestClient(mockApiClient(
        collection: [
          _gameJson(1, 'Wingspan'),
          _gameJson(2, 'Catan'),
          _gameJson(3, 'Azul'),
        ],
        plays: [
          {'game_id': 1, 'game_name': 'Wingspan', 'total_plays': 5},
          {'game_id': 2, 'game_name': 'Catan', 'total_plays': 0},
          {'game_id': 3, 'game_name': 'Azul', 'total_plays': 0},
        ],
      ));

      final model = AppModel();
      await model.addItem(Item('testuser'));

      await tester.pumpWidget(_buildTestApp(model));
      await tester.pumpAndSettle();

      expect(find.textContaining('2 unplayed'), findsOneWidget);
    });

    testWidgets('shows celebration message when all games played',
        (tester) async {
      HttpRetryClient.setTestClient(mockApiClient(
        collection: [
          _gameJson(1, 'Wingspan'),
          _gameJson(2, 'Catan'),
        ],
        plays: [
          {'game_id': 1, 'game_name': 'Wingspan', 'total_plays': 5},
          {'game_id': 2, 'game_name': 'Catan', 'total_plays': 3},
        ],
      ));

      final model = AppModel();
      await model.addItem(Item('testuser'));

      await tester.pumpWidget(_buildTestApp(model));
      await tester.pumpAndSettle();

      expect(find.text('No shame here!'), findsOneWidget);
    });

    testWidgets('shows BG Stats plug at bottom of list', (tester) async {
      HttpRetryClient.setTestClient(mockApiClient(
        collection: [
          _gameJson(1, 'Wingspan'),
        ],
        plays: [
          {'game_id': 1, 'game_name': 'Wingspan', 'total_plays': 0},
        ],
      ));

      final model = AppModel();
      await model.addItem(Item('testuser'));

      await tester.pumpWidget(_buildTestApp(model));
      await tester.pumpAndSettle();

      expect(find.text('Track your plays'), findsOneWidget);
      expect(find.textContaining('BG Stats'), findsOneWidget);
    });

    testWidgets('shows app bar with correct title', (tester) async {
      HttpRetryClient.setTestClient(mockApiClient());

      final model = AppModel();

      await tester.pumpWidget(_buildTestApp(model));
      await tester.pumpAndSettle();

      expect(find.text('Shelf of Shame'), findsOneWidget);
    });

    testWidgets('games with no play data are shown as unplayed',
        (tester) async {
      HttpRetryClient.setTestClient(mockApiClient(
        collection: [
          _gameJson(1, 'Wingspan'),
          _gameJson(2, 'Catan'),
          _gameJson(3, 'Azul'),
        ],
        plays: [
          {'game_id': 1, 'game_name': 'Wingspan', 'total_plays': 3},
        ],
      ));

      final model = AppModel();
      await model.addItem(Item('testuser'));

      await tester.pumpWidget(_buildTestApp(model));
      await tester.pumpAndSettle();

      expect(find.text('Catan'), findsOneWidget);
      expect(find.text('Azul'), findsOneWidget);
      expect(find.text('Wingspan'), findsNothing);
    });

    testWidgets('fetches full unfiltered collection', (tester) async {
      Map<String, String>? capturedHeaders;
      HttpRetryClient.setTestClient(
        SyncMockClient((request) {
          if (request.url.path.startsWith('/collection/')) {
            capturedHeaders = request.headers;
            return http.Response(jsonEncode([_gameJson(1, 'Wingspan')]), 200);
          }
          if (request.url.path.startsWith('/plays/')) {
            return http.Response(
                jsonEncode({
                  'plays': [],
                  'meta': {'complete': true}
                }),
                200);
          }
          return http.Response('Not found', 404);
        }),
      );

      final model = AppModel();
      await model.addItem(Item('testuser'));

      await tester.pumpWidget(_buildTestApp(model));
      await tester.pumpAndSettle();

      expect(capturedHeaders, isNotNull);
      expect(capturedHeaders!.containsKey('Bgg-Field-Whitelist'), isTrue);
      expect(capturedHeaders!.containsKey('Bgg-Filter-Player-Count'), isFalse);
      expect(capturedHeaders!.containsKey('Bgg-Filter-Min-Duration'), isFalse);
    });
  });
}

Map<String, dynamic> _gameJson(int id, String name) => {
      'id': id,
      'name': name,
      'minplayers': 2,
      'maxplayers': 4,
      'maxplaytime': 60,
      'image': 'http://example.com/$id.jpg',
      'thumbnail': null,
      'stats': {'average': 7.5, 'averageweight': 2.5},
    };
