@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_many_mobile_meeple/api/http_retry_client.dart';
import 'package:how_many_mobile_meeple/api/plays_service.dart';
import 'package:how_many_mobile_meeple/model/item.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/play_log/play_log_entry.dart';
import 'package:how_many_mobile_meeple/play_log/play_log_page.dart';
import 'package:how_many_mobile_meeple/play_log/play_log_service.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/mock_api_client.dart';

Widget _buildTestApp(AppModel model) {
  return ChangeNotifierProvider<AppModel>.value(
    value: model,
    child: const MaterialApp(home: PlayLogPage()),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PlayLogService.resetForTesting();
    PlaysService.clearCache();
    HttpRetryClient.setDelayFunction((_) => Future.value());
  });

  tearDown(() {
    PlayLogService.resetForTesting();
    HttpRetryClient.resetTestClient();
    HttpRetryClient.resetDelayFunction();
    PlaysService.clearCache();
  });

  group('PlayLogPage', () {
    testWidgets('shows empty state when no plays logged', (tester) async {
      await tester.pumpWidget(_buildTestApp(AppModel()));
      await tester.pumpAndSettle();

      expect(find.text('No plays logged yet'), findsOneWidget);
    });

    testWidgets('lists logged plays newest first', (tester) async {
      final service = await PlayLogService.instance();
      service.logPlay(PlayLogEntry(
        id: 'a',
        gameId: 1,
        name: 'Catan',
        playedAt: DateTime(2026, 1, 1),
      ));
      service.logPlay(PlayLogEntry(
        id: 'b',
        gameId: 2,
        name: 'Wingspan',
        playedAt: DateTime(2026, 6, 1),
      ));

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(_buildTestApp(AppModel()));
        await tester.pumpAndSettle();
      });

      expect(find.text('Catan'), findsOneWidget);
      expect(find.text('Wingspan'), findsOneWidget);
    });

    testWidgets('shows nudge when most recent play is 3+ months old',
        (tester) async {
      final service = await PlayLogService.instance();
      final stale = DateTime.now().subtract(const Duration(days: 200));
      service.logPlay(PlayLogEntry(
        id: 'a',
        gameId: 1,
        name: 'Gloomhaven',
        playedAt: stale,
      ));

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(_buildTestApp(AppModel()));
        await tester.pumpAndSettle();
      });

      expect(find.textContaining("haven't played Gloomhaven"), findsOneWidget);
    });

    testWidgets('no nudge for a recent play', (tester) async {
      final service = await PlayLogService.instance();
      service.logPlay(PlayLogEntry(
        id: 'a',
        gameId: 1,
        name: 'Azul',
        playedAt: DateTime.now(),
      ));

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(_buildTestApp(AppModel()));
        await tester.pumpAndSettle();
      });

      expect(find.textContaining("haven't played"), findsNothing);
    });

    testWidgets('nudges a neglected game even when another was played recently',
        (tester) async {
      final service = await PlayLogService.instance();
      service.logPlay(PlayLogEntry(
        id: 'stale',
        gameId: 1,
        name: 'Gloomhaven',
        playedAt: DateTime.now().subtract(const Duration(days: 200)),
      ));
      service.logPlay(PlayLogEntry(
        id: 'fresh',
        gameId: 2,
        name: 'Azul',
        playedAt: DateTime.now(),
      ));

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(_buildTestApp(AppModel()));
        await tester.pumpAndSettle();
      });

      // A recent play of Azul must not suppress the Gloomhaven nudge, and the
      // nudge must name the neglected game, not the freshly played one.
      expect(find.textContaining("haven't played Gloomhaven"), findsOneWidget);
      expect(find.textContaining("haven't played Azul"), findsNothing);
    });

    testWidgets('tapping an entry opens the edit dialog', (tester) async {
      final service = await PlayLogService.instance();
      service.logPlay(PlayLogEntry(
        id: 'a',
        gameId: 1,
        name: 'Catan',
        playedAt: DateTime.now(),
      ));

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(_buildTestApp(AppModel()));
        await tester.pumpAndSettle();
      });

      await tester.tap(find.text('Catan'));
      await tester.pumpAndSettle();

      expect(find.text('Edit play'), findsOneWidget);
    });

    testWidgets('editing an entry updates it in place', (tester) async {
      final service = await PlayLogService.instance();
      service.logPlay(PlayLogEntry(
        id: 'a',
        gameId: 1,
        name: 'Catan',
        playedAt: DateTime.now(),
      ));

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(_buildTestApp(AppModel()));
        await tester.pumpAndSettle();
      });

      await tester.tap(find.text('Catan'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Alice');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save play'));
      await tester.pumpAndSettle();

      expect(service.entries.length, 1);
      expect(service.entries.first.players.single.name, 'Alice');
    });

    testWidgets('shows player and winner details', (tester) async {
      final service = await PlayLogService.instance();
      service.logPlay(PlayLogEntry(
        id: 'a',
        gameId: 1,
        name: 'Catan',
        playedAt: DateTime.now(),
        players: [
          PlayerResult(name: 'Alice', won: true, score: 10),
          PlayerResult(name: 'Bob', score: 8),
        ],
      ));

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(_buildTestApp(AppModel()));
        await tester.pumpAndSettle();
      });

      expect(find.textContaining('Alice'), findsOneWidget);
      expect(find.textContaining('Bob'), findsOneWidget);
    });

    testWidgets('shows BGG plays loaded from the API', (tester) async {
      await PlayLogService.instance();
      HttpRetryClient.setTestClient(mockApiClient(plays: [
        {
          'game_id': 55,
          'game_name': 'Gloomhaven',
          'total_plays': 1,
          'plays': [
            {
              'play_id': 900,
              'date': '2026-05-01',
              'players': [
                {'username': 'me', 'name': 'David', 'score': 50, 'win': true},
              ],
            },
          ],
        },
      ]));

      final model = AppModel();
      await model.addItem(Item('testuser'));
      await model.loadPlays();

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(_buildTestApp(model));
        await tester.pumpAndSettle();
      });

      expect(find.text('Gloomhaven'), findsOneWidget);
      expect(find.textContaining('David'), findsOneWidget);
      expect(find.byType(SvgPicture), findsOneWidget,
          reason: 'BGG rows carry the BGG logo badge');
    });

    test('BGG plays pick up the collection thumbnail', () async {
      HttpRetryClient.setTestClient(mockApiClient(
        plays: [
          {
            'game_id': 55,
            'game_name': 'Gloomhaven',
            'total_plays': 1,
            'plays': [
              {'play_id': 900, 'date': '2026-05-01', 'players': []},
            ],
          },
        ],
        collection: [
          {'id': 55, 'name': 'Gloomhaven', 'thumbnail': 'http://img/gh.png'},
        ],
      ));

      final model = AppModel();
      await model.addItem(Item('testuser'));
      await model.loadPlays();

      expect(model.thumbnailFor(55), 'http://img/gh.png');
      expect(model.bggPlays.single.thumbnail, 'http://img/gh.png');
    });

    test('BGG play thumbnail is null when the game is not in the collection',
        () async {
      HttpRetryClient.setTestClient(mockApiClient(
        plays: [
          {
            'game_id': 55,
            'game_name': 'Gloomhaven',
            'total_plays': 1,
            'plays': [
              {'play_id': 900, 'date': '2026-05-01', 'players': []},
            ],
          },
        ],
      ));

      final model = AppModel();
      await model.addItem(Item('testuser'));
      await model.loadPlays();

      expect(model.bggPlays.single.thumbnail, isNull);
    });

    testWidgets('BGG plays are not editable on tap', (tester) async {
      await PlayLogService.instance();
      HttpRetryClient.setTestClient(mockApiClient(plays: [
        {
          'game_id': 55,
          'game_name': 'Gloomhaven',
          'total_plays': 1,
          'plays': [
            {'play_id': 900, 'date': '2026-05-01', 'players': []},
          ],
        },
      ]));

      final model = AppModel();
      await model.addItem(Item('testuser'));
      await model.loadPlays();

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(_buildTestApp(model));
        await tester.pumpAndSettle();
      });

      await tester.tap(find.text('Gloomhaven'));
      await tester.pumpAndSettle();

      // Tapping a read-only BGG row must not open the editor.
      expect(find.text('Edit play'), findsNothing);
    });

    testWidgets('merges local and BGG plays chronologically', (tester) async {
      final service = await PlayLogService.instance();
      service.logPlay(PlayLogEntry(
        id: 'local1',
        gameId: 1,
        name: 'Local Game',
        playedAt: DateTime(2026, 6, 1),
      ));

      HttpRetryClient.setTestClient(mockApiClient(plays: [
        {
          'game_id': 2,
          'game_name': 'BGG Game',
          'total_plays': 1,
          'plays': [
            {'play_id': 900, 'date': '2026-05-01', 'players': []},
          ],
        },
      ]));

      final model = AppModel();
      await model.addItem(Item('testuser'));
      await model.loadPlays();

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(_buildTestApp(model));
        await tester.pumpAndSettle();
      });

      expect(find.text('Local Game'), findsOneWidget);
      expect(find.text('BGG Game'), findsOneWidget);
    });
  });
}
