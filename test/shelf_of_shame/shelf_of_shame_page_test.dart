import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:how_many_mobile_meeple/api/http_retry_client.dart';
import 'package:how_many_mobile_meeple/api/plays_service.dart';
import 'package:how_many_mobile_meeple/model/item.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/shelf_of_shame/shelf_of_shame_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _buildTestApp(AppModel model) {
  return ChangeNotifierProvider<AppModel>.value(
    value: model,
    child: MaterialApp(
      home: const ShelfOfShamePage(),
    ),
  );
}

http_testing.MockClient _mockClient({
  required List<Map<String, dynamic>> collectionGames,
  required List<Map<String, dynamic>> playsData,
}) {
  return http_testing.MockClient((request) async {
    if (request.url.path.startsWith('/plays/')) {
      return http.Response(jsonEncode(playsData), 200);
    }
    if (request.url.path.startsWith('/collection/')) {
      return http.Response(jsonEncode(collectionGames), 200);
    }
    return http.Response('Not found', 404);
  });
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
      HttpRetryClient.setTestClient(
        http_testing.MockClient((_) async => http.Response('[]', 200)),
      );

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
      HttpRetryClient.setTestClient(
        http_testing.MockClient((_) async => http.Response('[]', 200)),
      );

      final model = AppModel();
      await model.addItem(Item('testuser'));
      model.primaryPlayer = null;

      await tester.pumpWidget(_buildTestApp(model));
      await tester.pumpAndSettle();

      expect(find.text('No primary player set'), findsOneWidget);
      expect(find.textContaining('crown icon'), findsOneWidget);
    });

    testWidgets('shows loading indicator while fetching', (tester) async {
      final completer = Completer<http.Response>();
      HttpRetryClient.setTestClient(
        http_testing.MockClient((request) {
          if (request.url.path.startsWith('/plays/')) {
            return completer.future;
          }
          return Future.value(http.Response('[]', 200));
        }),
      );

      final model = AppModel();
      await model.addItem(Item('testuser'));

      await tester.pumpWidget(_buildTestApp(model));
      await tester.pump();

      expect(find.byType(SpinKitCubeGrid), findsOneWidget);

      completer.complete(http.Response('[]', 200));
      await tester.pumpAndSettle();
    });

    testWidgets('shows collection banner with primary player name',
        (tester) async {
      HttpRetryClient.setTestClient(_mockClient(
        collectionGames: [
          _gameJson(1, 'Wingspan'),
          _gameJson(2, 'Catan'),
        ],
        playsData: [
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
      HttpRetryClient.setTestClient(_mockClient(
        collectionGames: [
          _gameJson(1, 'Wingspan'),
          _gameJson(2, 'Catan'),
          _gameJson(3, 'Azul'),
        ],
        playsData: [
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
      HttpRetryClient.setTestClient(_mockClient(
        collectionGames: [
          _gameJson(1, 'Wingspan'),
          _gameJson(2, 'Catan'),
          _gameJson(3, 'Azul'),
        ],
        playsData: [
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
      HttpRetryClient.setTestClient(_mockClient(
        collectionGames: [
          _gameJson(1, 'Wingspan'),
          _gameJson(2, 'Catan'),
        ],
        playsData: [
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
      HttpRetryClient.setTestClient(_mockClient(
        collectionGames: [
          _gameJson(1, 'Wingspan'),
        ],
        playsData: [
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
      HttpRetryClient.setTestClient(
        http_testing.MockClient((_) async => http.Response('[]', 200)),
      );

      final model = AppModel();

      await tester.pumpWidget(_buildTestApp(model));
      await tester.pumpAndSettle();

      expect(find.text('Shelf of Shame'), findsOneWidget);
    });

    testWidgets('games with no play data are shown as unplayed',
        (tester) async {
      HttpRetryClient.setTestClient(_mockClient(
        collectionGames: [
          _gameJson(1, 'Wingspan'),
          _gameJson(2, 'Catan'),
          _gameJson(3, 'Azul'),
        ],
        playsData: [
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
        http_testing.MockClient((request) async {
          if (request.url.path.startsWith('/collection/')) {
            capturedHeaders = request.headers;
            return http.Response(jsonEncode([_gameJson(1, 'Wingspan')]), 200);
          }
          return http.Response('[]', 200);
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
