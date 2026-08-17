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

Widget _buildTestApp(AppModel model, {Widget page = const ShelfOfShamePage()}) {
  return ChangeNotifierProvider<AppModel>.value(
    value: model,
    child: MaterialApp(home: page),
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
    testWidgets('shows no collection message when no collection added', (
      tester,
    ) async {
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
      },
    );

    testWidgets('shows loading indicator initially', (tester) async {
      HttpRetryClient.setTestClient(mockApiClient(collection: [], plays: []));

      final model = AppModel();
      await model.addItem(Item('testuser'));

      await tester.pumpWidget(_buildTestApp(model));

      expect(find.byType(SpinKitCubeGrid), findsOneWidget);
    });

    testWidgets('shows collection banner with primary player name', (
      tester,
    ) async {
      HttpRetryClient.setTestClient(
        mockApiClient(
          collection: [_gameJson(1, 'Wingspan'), _gameJson(2, 'Catan')],
          plays: [
            {'game_id': 1, 'game_name': 'Wingspan', 'total_plays': 5},
          ],
        ),
      );

      final model = AppModel();
      await model.addItem(Item('teqqles'));

      await tester.pumpWidget(_buildTestApp(model));
      await tester.pumpAndSettle();

      expect(find.textContaining("teqqles's collection"), findsOneWidget);
    });

    testWidgets(
      'banner reads as "viewing" when the shelf is for another player',
      (tester) async {
        HttpRetryClient.setTestClient(
          mockApiClient(collection: [_gameJson(1, 'Wingspan')], plays: []),
        );

        // Stored primary player is teqqles, but we followed a permalink for a
        // different collection.
        final model = AppModel();
        await model.addItem(Item('teqqles'));

        await tester.pumpWidget(
          _buildTestApp(
            model,
            page: const ShelfOfShamePage(username: 'linkeduser'),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.textContaining("Viewing linkeduser's shelf"),
          findsOneWidget,
        );
        expect(find.textContaining("teqqles's collection"), findsNothing);
      },
    );

    testWidgets(
      "linked shelf shows the linked user's unplayed games, not the primary "
      'player\'s',
      (tester) async {
        // linkeduser left Wingspan unplayed; teqqles (primary) played both. If the
        // page used the primary player's plays it would show "No shame here!".
        HttpRetryClient.setTestClient(
          SyncMockClient((request) {
            final path = request.url.path;
            if (path.startsWith('/collection/')) {
              return http.Response(
                jsonEncode([_gameJson(1, 'Wingspan'), _gameJson(2, 'Catan')]),
                200,
              );
            }
            if (path.contains('/plays/linkeduser')) {
              return http.Response(
                jsonEncode({
                  'plays': [
                    {'game_id': 2, 'game_name': 'Catan', 'total_plays': 3},
                  ],
                  'meta': {'complete': true},
                }),
                200,
              );
            }
            if (path.startsWith('/plays/')) {
              // teqqles (primary player) has played both games.
              return http.Response(
                jsonEncode({
                  'plays': [
                    {'game_id': 1, 'game_name': 'Wingspan', 'total_plays': 5},
                    {'game_id': 2, 'game_name': 'Catan', 'total_plays': 3},
                  ],
                  'meta': {'complete': true},
                }),
                200,
              );
            }
            return http.Response('Not found', 404);
          }),
        );

        final model = AppModel();
        await model.addItem(Item('teqqles'));

        await tester.pumpWidget(
          _buildTestApp(
            model,
            page: const ShelfOfShamePage(username: 'linkeduser'),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Wingspan'),
          findsOneWidget,
          reason: "unplayed for linkeduser, so it belongs on their shelf",
        );
        expect(
          find.text('Catan'),
          findsNothing,
          reason: 'linkeduser has played Catan',
        );
        expect(
          find.text('No shame here!'),
          findsNothing,
          reason: "must not fall back to the primary player's all-played plays",
        );
      },
    );

    testWidgets('shows only unplayed games from full collection', (
      tester,
    ) async {
      HttpRetryClient.setTestClient(
        mockApiClient(
          collection: [
            _gameJson(1, 'Wingspan'),
            _gameJson(2, 'Catan'),
            _gameJson(3, 'Azul'),
          ],
          plays: [
            {'game_id': 1, 'game_name': 'Wingspan', 'total_plays': 5},
            {'game_id': 2, 'game_name': 'Catan', 'total_plays': 0},
          ],
        ),
      );

      final model = AppModel();
      await model.addItem(Item('testuser'));

      await tester.pumpWidget(_buildTestApp(model));
      await tester.pumpAndSettle();

      expect(find.text('Catan'), findsOneWidget);
      expect(find.text('Azul'), findsOneWidget);
      expect(find.text('Wingspan'), findsNothing);
    });

    testWidgets('shows unplayed count in banner', (tester) async {
      HttpRetryClient.setTestClient(
        mockApiClient(
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
        ),
      );

      final model = AppModel();
      await model.addItem(Item('testuser'));

      await tester.pumpWidget(_buildTestApp(model));
      await tester.pumpAndSettle();

      expect(find.textContaining('2 unplayed'), findsOneWidget);
    });

    testWidgets('shows celebration message when all games played', (
      tester,
    ) async {
      HttpRetryClient.setTestClient(
        mockApiClient(
          collection: [_gameJson(1, 'Wingspan'), _gameJson(2, 'Catan')],
          plays: [
            {'game_id': 1, 'game_name': 'Wingspan', 'total_plays': 5},
            {'game_id': 2, 'game_name': 'Catan', 'total_plays': 3},
          ],
        ),
      );

      final model = AppModel();
      await model.addItem(Item('testuser'));

      await tester.pumpWidget(_buildTestApp(model));
      await tester.pumpAndSettle();

      expect(find.text('No shame here!'), findsOneWidget);
    });

    testWidgets('shows BG Stats plug at bottom of list', (tester) async {
      HttpRetryClient.setTestClient(
        mockApiClient(
          collection: [_gameJson(1, 'Wingspan')],
          plays: [
            {'game_id': 1, 'game_name': 'Wingspan', 'total_plays': 0},
          ],
        ),
      );

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

    testWidgets('games with no play data are shown as unplayed', (
      tester,
    ) async {
      HttpRetryClient.setTestClient(
        mockApiClient(
          collection: [
            _gameJson(1, 'Wingspan'),
            _gameJson(2, 'Catan'),
            _gameJson(3, 'Azul'),
          ],
          plays: [
            {'game_id': 1, 'game_name': 'Wingspan', 'total_plays': 3},
          ],
        ),
      );

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
                'meta': {'complete': true},
              }),
              200,
            );
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

    testWidgets('shows ownership date when lastmodified is recent', (
      tester,
    ) async {
      // Recent enough (under the 3-year threshold) to show the date line
      // rather than the worst-offender call-out. Pick a fixed month/day well
      // clear of "today" so the "Mar" label is stable regardless of run date.
      final recentYear = DateTime.now().year - 1;
      HttpRetryClient.setTestClient(
        mockApiClient(
          collection: [
            _gameJson(1, 'Catan', lastmodified: '$recentYear-03-15'),
          ],
          plays: [
            {'game_id': 1, 'game_name': 'Catan', 'total_plays': 0},
          ],
        ),
      );

      final model = AppModel();
      await model.addItem(Item('testuser'));

      await tester.pumpWidget(_buildTestApp(model));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Owned since Mar $recentYear'),
        findsOneWidget,
      );
    });

    testWidgets('shows worst-offender call-out for long-owned unplayed games', (
      tester,
    ) async {
      HttpRetryClient.setTestClient(
        mockApiClient(
          collection: [_gameJson(1, 'Gloomhaven', lastmodified: '2015-01-01')],
          plays: [
            {'game_id': 1, 'game_name': 'Gloomhaven', 'total_plays': 0},
          ],
        ),
      );

      final model = AppModel();
      await model.addItem(Item('testuser'));

      await tester.pumpWidget(_buildTestApp(model));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('years owned, still unplayed'),
        findsOneWidget,
      );
    });

    testWidgets('shows no date line when lastmodified is null', (tester) async {
      HttpRetryClient.setTestClient(
        mockApiClient(
          collection: [_gameJson(1, 'Azul', lastmodified: null)],
          plays: [
            {'game_id': 1, 'game_name': 'Azul', 'total_plays': 0},
          ],
        ),
      );

      final model = AppModel();
      await model.addItem(Item('testuser'));

      await tester.pumpWidget(_buildTestApp(model));
      await tester.pumpAndSettle();

      expect(find.text('Azul'), findsOneWidget);
      expect(find.textContaining('Owned since'), findsNothing);
      expect(find.textContaining('unplayed!'), findsNothing);
    });
  });
}

Map<String, dynamic> _gameJson(int id, String name, {String? lastmodified}) => {
  'id': id,
  'name': name,
  'minplayers': 2,
  'maxplayers': 4,
  'maxplaytime': 60,
  'image': 'http://example.com/$id.jpg',
  'thumbnail': null,
  'stats': {'average': 7.5, 'averageweight': 2.5},
  'lastmodified': lastmodified,
};
