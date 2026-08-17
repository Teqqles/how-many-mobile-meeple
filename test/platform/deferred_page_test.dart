@Tags(['widget'])
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:how_many_mobile_meeple/api/http_retry_client.dart';
import 'package:how_many_mobile_meeple/api/plays_service.dart';
import 'package:how_many_mobile_meeple/model/item.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/platform/router.dart' as r;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/sync_mock_client.dart';

Map<String, dynamic> _gameJson(int id, String name) => {
  'id': id,
  'name': name,
  'minplayers': 2,
  'maxplayers': 4,
  'maxplaytime': 60,
  'image': 'http://example.com/$id.jpg',
  'thumbnail': null,
  'stats': {'average': 7.5, 'averageweight': 2.5},
  'lastmodified': null,
};

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

  testWidgets(
    'a deferred route mounts once and does not reload when the model notifies',
    (tester) async {
      // Regression: a deferred page that fetches on mount once remounted on every
      // model notify, looping its collection fetch. Count fetches across notifies.
      var collectionCount = 0;
      HttpRetryClient.setTestClient(
        SyncMockClient((req) {
          final p = req.url.path;
          if (p.startsWith('/collection/') && !p.endsWith('/analytics')) {
            collectionCount++;
            return http.Response(
              jsonEncode([_gameJson(1, 'Wingspan'), _gameJson(2, 'Catan')]),
              200,
            );
          }
          if (p.startsWith('/plays/')) {
            return http.Response(
              jsonEncode({
                'plays': [],
                'meta': {'complete': true},
              }),
              200,
            );
          }
          return http.Response('nf', 404);
        }),
      );

      final model = AppModel();
      await model.addItem(Item('teqqles'));

      final navKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        ChangeNotifierProvider<AppModel>.value(
          value: model,
          // Mirror main.dart: the whole app rebuilds on every model change.
          child: Consumer<AppModel>(
            builder: (context, m, _) => MaterialApp(
              navigatorKey: navKey,
              home: const Scaffold(body: Center(child: Text('HOME'))),
              onGenerateRoute: r.Router.generateRoute,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      navKey.currentState!.pushNamed(r.Router.shelfOfShameRoute);
      await tester.pump(const Duration(milliseconds: 100));

      // Churn the model the way loadPlays/collection completion would.
      for (var i = 0; i < 8; i++) {
        model.refreshState();
        await tester.pump(const Duration(milliseconds: 100));
      }

      // The page's own fetch plus the model's collection fetch = 2. A reload loop
      // pushes this up by 2 on every rebuild.
      expect(
        collectionCount,
        lessThanOrEqualTo(2),
        reason: 'deferred page must not remount and refetch on model notifies',
      );
    },
  );
}
