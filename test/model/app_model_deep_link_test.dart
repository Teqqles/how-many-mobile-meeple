@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:how_many_mobile_meeple/api/http_retry_client.dart';
import 'package:how_many_mobile_meeple/api/plays_service.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';
import 'package:how_many_mobile_meeple/platform/web/url_fragment_extractor.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/mock_api_client.dart';

AppModel _modelForFragment(String fragment) {
  final uri = Uri(fragment: fragment);
  return AppModel(urlExtractor: UrlFragmentExtractor(uri));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PlaysService.clearCache();
    HttpRetryClient.setDelayFunction((_) => Future.value());
    HttpRetryClient.setTestClient(mockApiClient());
  });

  tearDown(() {
    HttpRetryClient.resetTestClient();
    HttpRetryClient.resetDelayFunction();
    PlaysService.clearCache();
  });

  group('deep-link bootstrap (hard refresh onto a non-home page)', () {
    test('loadStoredData applies URL items when the fragment encodes a model',
        () async {
      // A hard refresh onto /random with a shared collection in the fragment.
      final model = _modelForFragment('/random/deeplinkuser');

      await model.loadStoredData();

      expect(model.hasLoadedPersistedData, true);
      expect(model.items.itemList.map((i) => i.name), contains('deeplinkuser'));
    });

    test('loadStoredData applies URL settings when present in the fragment',
        () async {
      final model = _modelForFragment('/list/deeplinkuser?numberOfPlayers=6');

      await model.loadStoredData();

      final setting =
          model.settings.setting(Settings.filterNumberOfPlayers.name);
      expect(setting.value.toString(), '6');
    });

    test('refreshFromUrl after loadStoredData does not double-apply the model',
        () async {
      final model = _modelForFragment('/random/deeplinkuser');

      await model.loadStoredData();
      // Home pages also call refreshFromUrl(); it must be a no-op once consumed.
      await model.refreshFromUrl();

      final userCount =
          model.items.itemList.where((i) => i.name == 'deeplinkuser').length;
      expect(userCount, 1);
    });

    test(
        'game detail deep link does not wire the game id in as a source and '
        'loads stored parameters instead', () async {
      // Stored collection from a previous visit.
      SharedPreferences.setMockInitialValues({
        'primary_player': 'storeduser',
        'bgg-item-0': '{"name":"storeduser","item_type":{"name":"collection"}}',
      });

      // Hard refresh straight onto a game page.
      final model = _modelForFragment('/game/Gloomhaven/174430');

      await model.loadStoredData();

      final names = model.items.itemList.map((i) => i.name).toList();
      expect(names, isNot(contains('174430')),
          reason: 'the game id must not become a source');
      expect(names, contains('storeduser'),
          reason: 'stored parameters should load when no URL model is present');
    });

    test('shelf of shame permalink is view-only and leaves stored data intact',
        () async {
      // A previous session left a stored primary player and collection behind.
      SharedPreferences.setMockInitialValues({
        'primary_player': 'storeduser',
        'bgg-item-0': '{"name":"storeduser","item_type":{"name":"collection"}}',
      });

      // Following a shared shelf of shame permalink for a different collection.
      // The trailing username is a route parameter the page consumes directly,
      // not an encoded model - treating it as one seeded a bogus source and
      // spun the page in a reload loop that spammed the collection API, so
      // bootstrapping must leave the stored model untouched.
      final model = _modelForFragment('/shelf-of-shame/linkeduser');

      await model.loadStoredData();

      expect(model.primaryPlayer, 'storeduser',
          reason: 'a shelf of shame permalink must not swap the stored player');
      expect(model.items.itemList.map((i) => i.name), contains('storeduser'),
          reason: 'the stored collection must survive the permalink');
      expect(model.items.itemList.map((i) => i.name),
          isNot(contains('linkeduser')),
          reason: 'the permalink username must not become a source');
    });
  });
}
