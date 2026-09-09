@Tags(['widget'])
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:how_many_mobile_meeple/api/http_retry_client.dart';
import 'package:how_many_mobile_meeple/api/plays_service.dart';
import 'package:how_many_mobile_meeple/favourites/favourites_service.dart';
import 'package:how_many_mobile_meeple/favourites/ignored_games_service.dart';
import 'package:how_many_mobile_meeple/guided_flow_homepage.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/platform/router.dart' as r;
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/sync_mock_client.dart';

// The mode toggle keeps the URL in step with the view, and a bare route's path
// decides the mode on load - so a copied link reopens the right mode.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PlaysService.clearCache();
    HttpRetryClient.setDelayFunction((_) => Future.value());
    HttpRetryClient.setTestClient(
      SyncMockClient((request) {
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
          return http.Response(jsonEncode(<Map<String, dynamic>>[]), 200);
        }
        return http.Response('Not found', 404);
      }),
    );
  });

  tearDown(() {
    HttpRetryClient.resetTestClient();
    HttpRetryClient.resetDelayFunction();
    PlaysService.clearCache();
    IgnoredGamesService.resetForTesting();
    FavouritesService.resetForTesting();
  });

  Future<GoRouter> pumpRoutedHome(
    WidgetTester tester, {
    String initialLocation = '/',
  }) async {
    // Shared key mirrors the real Router: toggling rewrites the URL, no remount.
    final home = MaterialPage(
      key: const ValueKey('home'),
      child: GuidedFlowHomePage(),
    );
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(path: r.Router.homeRoute, pageBuilder: (_, _) => home),
        GoRoute(path: r.Router.gameNightRoute, pageBuilder: (_, _) => home),
      ],
    );
    await tester.pumpWidget(
      ChangeNotifierProvider<AppModel>.value(
        value: AppModel(),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  String locationOf(GoRouter router) =>
      router.routeInformationProvider.value.uri.toString();

  testWidgets('switching to Game Night rewrites the URL to /gameNight', (
    tester,
  ) async {
    final router = await pumpRoutedHome(tester);
    expect(locationOf(router), r.Router.homeRoute);

    await tester.tap(find.text('Game Night').first);
    await tester.pumpAndSettle();

    expect(locationOf(router), r.Router.gameNightRoute);
  });

  testWidgets('switching back to One Game rewrites the URL to /', (
    tester,
  ) async {
    final router = await pumpRoutedHome(tester);

    await tester.tap(find.text('Game Night').first);
    await tester.pumpAndSettle();
    expect(locationOf(router), r.Router.gameNightRoute);

    await tester.tap(find.text('One Game').first);
    await tester.pumpAndSettle();
    expect(locationOf(router), r.Router.homeRoute);
  });

  // "Step 1 of 5" renders only in One Game mode, distinguishing the two views.
  testWidgets('a fresh load of / shows One Game', (tester) async {
    await pumpRoutedHome(tester, initialLocation: r.Router.homeRoute);
    expect(find.text('Step 1 of 5'), findsOneWidget);
  });

  testWidgets('a fresh load of /gameNight shows Game Night', (tester) async {
    await pumpRoutedHome(tester, initialLocation: r.Router.gameNightRoute);
    expect(find.text('Step 1 of 5'), findsNothing);
  });
}
