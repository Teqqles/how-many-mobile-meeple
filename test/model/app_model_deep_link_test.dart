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

AppModel _modelForLocation(String location) {
  return AppModel(urlExtractor: UrlFragmentExtractor.fromLocation(location));
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
    test(
      'loadStoredData applies URL items when the fragment encodes a model',
      () async {
        // A hard refresh onto /random with a shared collection in the fragment.
        final model = _modelForLocation('/random/deeplinkuser');

        await model.loadStoredData();

        expect(model.hasLoadedPersistedData, true);
        expect(
          model.items.itemList.map((i) => i.name),
          contains('deeplinkuser'),
        );
      },
    );

    test(
      'loadStoredData applies URL settings when present in the fragment',
      () async {
        final model = _modelForLocation('/list/deeplinkuser?numberOfPlayers=6');

        await model.loadStoredData();

        final setting = model.settings.setting(
          Settings.filterNumberOfPlayers.name,
        );
        expect(setting.value.toString(), '6');
      },
    );

    test(
      'refreshFromUrl after loadStoredData does not double-apply the model',
      () async {
        final model = _modelForLocation('/random/deeplinkuser');

        await model.loadStoredData();
        // Home pages also call refreshFromUrl(); it must be a no-op once consumed.
        await model.refreshFromUrl();

        final userCount = model.items.itemList
            .where((i) => i.name == 'deeplinkuser')
            .length;
        expect(userCount, 1);
      },
    );

    test('game detail deep link does not wire the game id in as a source and '
        'loads stored parameters instead', () async {
      // Stored collection from a previous visit.
      SharedPreferences.setMockInitialValues({
        'primary_player': 'storeduser',
        'bgg-item-0': '{"name":"storeduser","item_type":{"name":"collection"}}',
      });

      // Hard refresh straight onto a game page.
      final model = _modelForLocation('/game/Gloomhaven/174430');

      await model.loadStoredData();

      final names = model.items.itemList.map((i) => i.name).toList();
      expect(
        names,
        isNot(contains('174430')),
        reason: 'the game id must not become a source',
      );
      expect(
        names,
        contains('storeduser'),
        reason: 'stored parameters should load when no URL model is present',
      );
    });

    test('shelf of shame permalink is view-only and leaves stored data intact', () async {
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
      final model = _modelForLocation('/shelf-of-shame/linkeduser');

      await model.loadStoredData();

      expect(
        model.primaryPlayer,
        'storeduser',
        reason: 'a shelf of shame permalink must not swap the stored player',
      );
      expect(
        model.items.itemList.map((i) => i.name),
        contains('storeduser'),
        reason: 'the stored collection must survive the permalink',
      );
      expect(
        model.items.itemList.map((i) => i.name),
        isNot(contains('linkeduser')),
        reason: 'the permalink username must not become a source',
      );
    });
  });

  group('deep link opened in a running app (no reload)', () {
    test('applyRouteUrl loads a collection the construction-time URL never carried', () async {
      // An existing visitor: no model in the URL at start-up, stored data loads.
      final model = _modelForLocation('/');
      await model.loadStoredData();
      expect(
        model.items.itemList.map((i) => i.name),
        isNot(contains('teqqles')),
      );

      // They open a shared Game Night link. Flutter pushes it as a new route
      // (Uri.base is unchanged), so the model only learns of it via the route
      // name handed to applyRouteUrl.
      await model.applyRouteUrl(
        '/gameNight/teqqles?gameNightLineup=822-243759-251661-223770',
      );

      expect(
        model.items.itemList.map((i) => i.name),
        contains('teqqles'),
        reason: 'the opened collection must load',
      );
      expect(
        model.settings.setting(Settings.gameNightMode.name).enabled,
        true,
        reason: 'the /gameNight prefix must switch on Game Night mode',
      );
      expect(
        model.settings.setting(Settings.gameNightLineup.name).getString(),
        '822-243759-251661-223770',
        reason: 'the shared lineup must be carried into settings',
      );
    });

    test('applyRouteUrl re-restores the shared lineup when the same link is '
        'visited again after its single-use lineup was consumed', () async {
      final model = _modelForLocation('/');
      await model.loadStoredData();

      const link =
          '/gameNight/teqqles?gameNightLineup=822-243759-251661-223770';
      await model.applyRouteUrl(link);

      // The first visit's GameNightView consumes the single-use lineup: it
      // blanks and disables the setting once the games are pinned.
      final consumed = model.settings.setting(Settings.gameNightLineup.name)
        ..value = ''
        ..enabled = false;
      model.settings.updateSetting(consumed);

      // Re-visiting the same link (a fresh page mount) must re-read the lineup
      // from the URL, not show the consumed, empty one.
      await model.applyRouteUrl(link);

      expect(
        model.settings.setting(Settings.gameNightLineup.name).getString(),
        '822-243759-251661-223770',
      );
      expect(
        model.settings.setting(Settings.gameNightLineup.name).enabled,
        true,
      );
    });

    test('the shared lineup is a URL-only token that is never persisted, so a '
        'later plain visit does not resurface it', () async {
      // Open a shared link, then persist - as the app does after restoring.
      final shared = _modelForLocation('/');
      await shared.loadStoredData();
      await shared.applyRouteUrl(
        '/gameNight/teqqles?gameNightLineup=822-243759-251661-223770',
      );
      await shared.updateStore();

      // A later visit with no model in the URL loads only stored data.
      final later = _modelForLocation('/');
      await later.loadStoredData();

      final lineup = later.settings.setting(Settings.gameNightLineup.name);
      expect(lineup.enabled, false, reason: 'the lineup must not persist');
      expect(lineup.getString(), '');
    });
  });
}
