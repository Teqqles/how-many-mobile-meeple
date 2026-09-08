@Tags(['widget'])
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_many_mobile_meeple/api/http_retry_client.dart';
import 'package:how_many_mobile_meeple/api/plays_service.dart';
import 'package:how_many_mobile_meeple/favourites/favourites_service.dart';
import 'package:how_many_mobile_meeple/favourites/ignored_games_service.dart';
import 'package:how_many_mobile_meeple/guided_flow_homepage.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/platform/web/url_fragment_extractor.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/sync_mock_client.dart';

Map<String, dynamic> _gameJson(int id, String name) => {
  'id': id,
  'name': name,
  'minplayers': 2,
  'maxplayers': 4,
  'maxplaytime': 60,
  'image': '',
  'thumbnail': null,
  'stats': {'average': 7.5, 'averageweight': 2.5},
};

SyncMockClient _client(List<Map<String, dynamic>> collection) {
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
      return http.Response(jsonEncode(collection), 200);
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

  Future<void> pumpHome(WidgetTester tester, String fragment) async {
    final model = AppModel(
      urlExtractor: UrlFragmentExtractor(Uri(fragment: fragment)),
    );
    await tester.pumpWidget(
      ChangeNotifierProvider<AppModel>.value(
        value: model,
        child: MaterialApp(home: GuidedFlowHomePage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'an old-form ?gameNightMode link opens Game Night and pins the lineup',
    (tester) async {
      HttpRetryClient.setTestClient(
        _client([
          _gameJson(180974, 'Filler Game'),
          _gameJson(349963, 'Main Game'),
          _gameJson(251661, 'Backup Game'),
          _gameJson(999001, 'Decoy One'),
          _gameJson(999002, 'Decoy Two'),
        ]),
      );

      await pumpHome(
        tester,
        '/teqqles?gameNightMode=true'
        '&gameNightLineup=180974-349963-251661-0'
        '&gameNightPlayerCount=4',
      );

      expect(find.text('Filler Game'), findsOneWidget);
      expect(find.text('Main Game'), findsOneWidget);
      expect(find.text('Backup Game'), findsOneWidget);
    },
  );

  testWidgets(
    'a new-form /gameNight link opens Game Night and pins the lineup',
    (tester) async {
      HttpRetryClient.setTestClient(
        _client([
          _gameJson(180974, 'Filler Game'),
          _gameJson(349963, 'Main Game'),
          _gameJson(251661, 'Backup Game'),
          _gameJson(999001, 'Decoy One'),
          _gameJson(999002, 'Decoy Two'),
        ]),
      );

      await pumpHome(
        tester,
        '/gameNight/teqqles?gameNightLineup=180974-349963-251661-0'
        '&gameNightPlayerCount=4',
      );

      expect(find.text('Filler Game'), findsOneWidget);
      expect(find.text('Main Game'), findsOneWidget);
      expect(find.text('Backup Game'), findsOneWidget);
    },
  );
}
