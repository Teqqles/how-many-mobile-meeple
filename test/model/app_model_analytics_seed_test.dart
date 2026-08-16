@Tags(['unit'])
library;

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:how_many_mobile_meeple/api/http_retry_client.dart';
import 'package:how_many_mobile_meeple/api/plays_service.dart';
import 'package:how_many_mobile_meeple/model/item.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/sync_mock_client.dart';

final _readyAnalytics = jsonEncode({
  'summary': {'average_weight': 2.3},
  'playtime_distribution': [
    {'label': 'short [30, 60)', 'count': 32}
  ],
  'player_count_coverage': [
    {'player_count': 4, 'best_or_recommended': 99}
  ],
  'top_mechanics': [
    {'name': 'Hand Management', 'count': 43},
    {'name': 'Set Collection', 'count': 39},
  ],
});

http.Response _route(http.BaseRequest req, {required bool analyticsOk}) {
  final path = req.url.path;
  if (path.endsWith('/analytics')) {
    if (!analyticsOk) return http.Response('error', 500);
    return http.Response(_readyAnalytics, 200);
  }
  if (path.startsWith('/plays/')) {
    return http.Response(
        jsonEncode({
          'plays': [],
          'meta': {'complete': true}
        }),
        200);
  }
  if (path.startsWith('/collection/')) {
    return http.Response(jsonEncode([]), 200);
  }
  return http.Response('not found', 404);
}

http.Response _routePlaysAndCollection(http.BaseRequest req) {
  final path = req.url.path;
  if (path.startsWith('/plays/')) {
    return http.Response(
        jsonEncode({
          'plays': [],
          'meta': {'complete': true}
        }),
        200);
  }
  if (path.startsWith('/collection/')) {
    return http.Response(jsonEncode([]), 200);
  }
  return http.Response('not found', 404);
}

/// Pumps the event loop so zero-delay retry timers can fire.
Future<void> _pumpUntil(bool Function() done, {int maxTurns = 200}) async {
  for (var i = 0; i < maxTurns && !done(); i++) {
    await Future.delayed(Duration.zero);
  }
}

int _players(AppModel model) =>
    model.settings.setting(Settings.filterNumberOfPlayers.name).value as int;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PlaysService.clearCache();
    HttpRetryClient.setDelayFunction((_) => Future.value());
    AppModel.analyticsRetryDelaySeconds = 0;
  });
  tearDown(() {
    HttpRetryClient.resetTestClient();
    HttpRetryClient.resetDelayFunction();
    PlaysService.clearCache();
    AppModel.analyticsRetryDelaySeconds = 3;
  });

  test('seeds untouched filters after loadPlays', () async {
    HttpRetryClient.setTestClient(
        SyncMockClient((req) => _route(req, analyticsOk: true)));
    final model = AppModel();
    addTearDown(model.dispose);
    await model.addItem(Item('teqqles'));
    await model.loadPlays();
    await model.analyticsSeedFuture;

    expect(_players(model), 4);
    expect(model.settings.setting(Settings.filterMinimumTimeToPlay.name).value,
        30);
    expect(model.settings.setting(Settings.filterComplexity.name).value, 2.3);
    // Position-only: not enabled.
    expect(model.settings.setting(Settings.filterNumberOfPlayers.name).enabled,
        isFalse);
  });

  test('adding the first collection seeds without an explicit loadPlays',
      () async {
    HttpRetryClient.setTestClient(
        SyncMockClient((req) => _route(req, analyticsOk: true)));
    final model = AppModel();
    addTearDown(model.dispose);

    // addItem establishes the primary player and must trigger seeding itself.
    await model.addItem(Item('teqqles'));
    await model.analyticsSeedFuture;

    expect(_players(model), 4);
  });

  test('retains fetched analytics on the model after seeding', () async {
    HttpRetryClient.setTestClient(
        SyncMockClient((req) => _route(req, analyticsOk: true)));
    final model = AppModel();
    addTearDown(model.dispose);
    expect(model.collectionAnalytics, isNull);

    await model.addItem(Item('teqqles'));
    await model.analyticsSeedFuture;

    expect(model.collectionAnalytics, isNotNull);
    expect(model.topMechanics.map((m) => m.name).toList(),
        ['Hand Management', 'Set Collection']);
  });

  test('leaves analytics null when the fetch never succeeds', () async {
    HttpRetryClient.setTestClient(
        SyncMockClient((req) => _route(req, analyticsOk: false)));
    final model = AppModel();
    addTearDown(model.dispose);
    await model.addItem(Item('teqqles'));
    await model.analyticsSeedFuture;

    expect(model.collectionAnalytics, isNull);
    expect(model.topMechanics, isEmpty);
  });

  test('failed analytics leaves settings unchanged', () async {
    HttpRetryClient.setTestClient(
        SyncMockClient((req) => _route(req, analyticsOk: false)));
    final model = AppModel();
    addTearDown(model.dispose);
    final before = _players(model);
    await model.addItem(Item('teqqles'));
    await model.loadPlays();
    await model.analyticsSeedFuture;

    expect(_players(model), before);
  });

  test('does not refetch analytics for the same username twice', () async {
    var analyticsCalls = 0;
    HttpRetryClient.setTestClient(SyncMockClient((req) {
      if (req.url.path.endsWith('/analytics')) analyticsCalls++;
      return _route(req, analyticsOk: true);
    }));
    final model = AppModel();
    addTearDown(model.dispose);
    await model.addItem(Item('teqqles'));
    await model.loadPlays();
    await model.analyticsSeedFuture;
    PlaysService.clearCache();
    await model.loadPlays();
    await model.analyticsSeedFuture;

    expect(analyticsCalls, 1);
  });

  test('retries and seeds when analytics is not ready on the first call',
      () async {
    var analyticsCalls = 0;
    HttpRetryClient.setTestClient(SyncMockClient((req) {
      if (req.url.path.endsWith('/analytics')) {
        analyticsCalls++;
        // First response is a not-ready 200 (empty sections); then ready.
        return analyticsCalls == 1
            ? http.Response(jsonEncode({}), 200)
            : http.Response(_readyAnalytics, 200);
      }
      return _routePlaysAndCollection(req);
    }));
    final model = AppModel();
    addTearDown(model.dispose);
    await model.addItem(Item('teqqles'));
    await model.loadPlays();
    await model.analyticsSeedFuture;

    // Not seeded yet on the first, not-ready response.
    expect(_players(model), isNot(4));

    await _pumpUntil(() => _players(model) == 4);
    expect(_players(model), 4);
    expect(analyticsCalls, greaterThanOrEqualTo(2));
  });

  test('stops retrying after the maximum number of attempts', () async {
    var analyticsCalls = 0;
    HttpRetryClient.setTestClient(SyncMockClient((req) {
      if (req.url.path.endsWith('/analytics')) {
        analyticsCalls++;
        return http.Response(jsonEncode({}), 200); // never ready
      }
      return _routePlaysAndCollection(req);
    }));
    final model = AppModel();
    addTearDown(model.dispose);
    await model.addItem(Item('teqqles'));
    await model.loadPlays();
    await model.analyticsSeedFuture;

    await _pumpUntil(() => analyticsCalls >= 6, maxTurns: 300);
    final settled = analyticsCalls;
    await _pumpUntil(() => false, maxTurns: 40); // confirm no further attempts

    // 1 initial attempt + at most 5 bounded retries.
    expect(settled, 6);
    expect(analyticsCalls, 6);
    expect(_players(model),
        Settings.filterNumberOfPlayers.value); // untouched default
  });
}
