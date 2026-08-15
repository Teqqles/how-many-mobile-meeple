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

http.Response _route(http.BaseRequest req, {required bool analyticsOk}) {
  final path = req.url.path;
  if (path.endsWith('/analytics')) {
    if (!analyticsOk) return http.Response('error', 500);
    return http.Response(
        jsonEncode({
          'summary': {'average_weight': 2.3},
          'playtime_distribution': [
            {'label': 'short [30, 60)', 'count': 32}
          ],
          'player_count_coverage': [
            {'player_count': 4, 'best_or_recommended': 99}
          ],
        }),
        200);
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
  });

  test('seeds untouched filters after loadPlays', () async {
    HttpRetryClient.setTestClient(
        SyncMockClient((req) => _route(req, analyticsOk: true)));
    final model = AppModel();
    await model.addItem(Item('teqqles'));
    await model.loadPlays();
    await model.analyticsSeedFuture;

    expect(
        model.settings.setting(Settings.filterNumberOfPlayers.name).value, 4);
    expect(model.settings.setting(Settings.filterMinimumTimeToPlay.name).value,
        30);
    expect(model.settings.setting(Settings.filterComplexity.name).value, 2.3);
    // Position-only: not enabled.
    expect(model.settings.setting(Settings.filterNumberOfPlayers.name).enabled,
        isFalse);
  });

  test('failed analytics leaves settings unchanged', () async {
    HttpRetryClient.setTestClient(
        SyncMockClient((req) => _route(req, analyticsOk: false)));
    final model = AppModel();
    final before =
        model.settings.setting(Settings.filterNumberOfPlayers.name).value;
    await model.addItem(Item('teqqles'));
    await model.loadPlays();
    await model.analyticsSeedFuture;

    expect(model.settings.setting(Settings.filterNumberOfPlayers.name).value,
        before);
  });

  test('does not refetch analytics for the same username twice', () async {
    var analyticsCalls = 0;
    HttpRetryClient.setTestClient(SyncMockClient((req) {
      if (req.url.path.endsWith('/analytics')) analyticsCalls++;
      return _route(req, analyticsOk: true);
    }));
    final model = AppModel();
    await model.addItem(Item('teqqles'));
    await model.loadPlays();
    await model.analyticsSeedFuture;
    PlaysService.clearCache();
    await model.loadPlays();
    await model.analyticsSeedFuture;

    expect(analyticsCalls, 1);
  });
}
