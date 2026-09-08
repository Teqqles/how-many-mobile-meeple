@Tags(['widget'])
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_many_mobile_meeple/api/http_retry_client.dart';
import 'package:how_many_mobile_meeple/api/plays_service.dart';
import 'package:how_many_mobile_meeple/favourites/favourites_service.dart';
import 'package:how_many_mobile_meeple/favourites/ignored_games_service.dart';
import 'package:how_many_mobile_meeple/game_night/game_night_content.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/platform/web/url_fragment_extractor.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/sync_mock_client.dart';

Map<String, dynamic> _gameJson(
  int id,
  String name, {
  int minPlayers = 2,
  int maxPlayers = 4,
  int maxPlaytime = 60,
}) => {
  'id': id,
  'name': name,
  'minplayers': minPlayers,
  'maxplayers': maxPlayers,
  'maxplaytime': maxPlaytime,
  'image': '',
  'thumbnail': null,
  'stats': {'average': 7.5, 'averageweight': 2.5},
};

/// A mock BGG proxy that mirrors production: it applies the player-count filter
/// the client asks for via the `Bgg-Filter-Player-Count` header, so a game the
/// count excludes never reaches the app.
SyncMockClient _filteringClient(List<Map<String, dynamic>> collection) {
  return SyncMockClient((request) {
    if (request.url.path.startsWith('/plays/')) {
      return http.Response(
        jsonEncode({
          'plays': [],
          'meta': {'complete': true},
        }),
        200,
      );
    }
    if (request.url.path.startsWith('/collection/')) {
      final countHeader = request.headers['bgg-filter-player-count'];
      var games = collection;
      if (countHeader != null) {
        final count = int.parse(countHeader);
        games = collection
            .where(
              (g) =>
                  (g['minplayers'] as int) <= count &&
                  count <= (g['maxplayers'] as int),
            )
            .toList();
      }
      return http.Response(jsonEncode(games), 200);
    }
    return http.Response('Not found', 404);
  });
}

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
    IgnoredGamesService.resetForTesting();
    FavouritesService.resetForTesting();
  });

  testWidgets(
    'a shared lineup restores every game even when the player-count filter '
    'would exclude one',
    (tester) async {
      // The night's outro is a cosy two-player closer; everything else seats a
      // full table of four.
      HttpRetryClient.setTestClient(
        _filteringClient([
          _gameJson(101, 'Warmup', maxPlaytime: 20),
          _gameJson(102, 'Centrepiece', maxPlaytime: 90),
          _gameJson(103, 'Alternative', maxPlaytime: 80),
          _gameJson(
            104,
            'Nightcap',
            minPlayers: 2,
            maxPlayers: 2,
            maxPlaytime: 30,
          ),
          _gameJson(201, 'Decoy A'),
          _gameJson(202, 'Decoy B'),
        ]),
      );

      // A shared permalink: four pinned games and a four-player table.
      final model = AppModel(
        urlExtractor: UrlFragmentExtractor.fromLocation(
          '/gameNight/teqqles?gameNightDurationMinutes=300'
          '&gameNightLineup=101-102-103-104'
          '&gameNightPlayerCount=4',
        ),
      );
      await model.loadStoredData();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: GameNightContent(model: model)),
        ),
      );
      await tester.pumpAndSettle();

      // The recipient must see the exact lineup that was shared - including the
      // two-player nightcap the count-of-four filter would otherwise drop.
      expect(find.text('Warmup'), findsOneWidget);
      expect(find.text('Centrepiece'), findsOneWidget);
      expect(find.text('Alternative'), findsOneWidget);
      expect(
        find.text('Nightcap'),
        findsOneWidget,
        reason: 'the shared game must survive the player-count filter',
      );
      // And none of the pool decoys sneak into a slot.
      expect(find.text('Decoy A'), findsNothing);
      expect(find.text('Decoy B'), findsNothing);
    },
  );
}
