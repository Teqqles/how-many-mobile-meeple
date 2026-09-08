@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:how_many_mobile_meeple/api/http_retry_client.dart';
import 'package:how_many_mobile_meeple/api/plays_service.dart';
import 'package:how_many_mobile_meeple/model/game.dart';
import 'package:how_many_mobile_meeple/model/game_night.dart';
import 'package:how_many_mobile_meeple/model/item.dart';
import 'package:how_many_mobile_meeple/model/items.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';
import 'package:how_many_mobile_meeple/platform/router.dart';
import 'package:how_many_mobile_meeple/platform/web/url_fragment_encoder.dart';
import 'package:how_many_mobile_meeple/platform/web/url_fragment_extractor.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/mock_api_client.dart';

Game _game(int id, int maxPlaytime) => Game(
  id: id,
  name: 'Game $id',
  maxPlayers: 4,
  minPlayers: 2,
  maxPlaytime: maxPlaytime,
  imageUrl: '',
  averageRating: 7,
  averageWeight: 2.5,
);

/// The fragment part of a permalink is what the browser keeps after `#`. On a
/// refresh, Flutter web parses that fragment as a [Uri] to drive routing, so a
/// permalink only survives a refresh if the collection sources live in the Uri
/// *path* - not swallowed into the authority by a stray leading `//`.
Uri _parseFragment(String url) => Uri.parse(Uri.parse(url).fragment);

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

  test('the game-night permalink keeps the collection in the path, not the '
      'authority, so a refresh does not drop it', () async {
    final sender = AppModel();
    await sender.replaceItems(Items([Item('teqqles'), Item('dragonc')]));
    final lineup = GameNightLineup(
      filler: _game(343900, 20),
      main: _game(263895, 90),
      backup: _game(97842, 80),
      outro: _game(205610, 30),
    );

    final url = Router.gameNightPermalink(sender, lineup);
    final fragment = _parseFragment(url);

    // A leading `//` makes `Uri.parse` read the collection as a host; a refresh
    // then strips it, losing the sources.
    expect(
      fragment.hasAuthority,
      isFalse,
      reason: 'the collection must not be parsed as a URL authority',
    );
    expect(
      fragment.path,
      startsWith('/gameNight/'),
      reason: 'a Game Night link carries mode in its path prefix',
    );
    expect(
      fragment.path,
      contains('teqqles'),
      reason: 'the collection must survive in the path across a refresh',
    );
  });

  test('a refreshed game-night permalink still restores the collection and '
      'lineup', () async {
    final sender = AppModel();
    await sender.replaceItems(Items([Item('teqqles'), Item('dragonc')]));
    final lineup = GameNightLineup(
      filler: _game(343900, 20),
      main: _game(263895, 90),
      backup: _game(97842, 80),
    );

    final url = Router.gameNightPermalink(sender, lineup);

    // Simulate a hard refresh: Flutter web routes on the Uri path (plus query),
    // so anything that landed in the authority is gone by the time the app
    // reads the fragment back.
    final parsed = _parseFragment(url);
    final refreshedFragment = Uri(
      path: parsed.path,
      query: parsed.query.isEmpty ? null : parsed.query,
    ).toString();
    final extractor = UrlFragmentExtractor(Uri(fragment: refreshedFragment));

    expect(
      extractor.extractItems().itemList.map((i) => i.name),
      containsAll(['teqqles', 'dragonc']),
      reason: 'both collections must survive a refresh',
    );
    final settings = extractor.extractSettings();
    expect(
      settings.setting(Settings.gameNightMode.name).getBool(),
      isTrue,
      reason: 'the /gameNight path prefix must reopen Game Night mode',
    );
    expect(
      settings.setting(Settings.gameNightLineup.name).getString(),
      '343900-263895-97842-0',
    );
  });

  test(
    'the permalink leaves the one-game guided-flow filters out of the link',
    () async {
      final sender = AppModel();
      await sender.replaceItems(Items([Item('teqqles')]));
      // The sender had one-game filters set from an earlier picking session.
      for (final name in [
        Settings.filterMinimumTimeToPlay.name,
        Settings.filterMaximumTimeToPlay.name,
        Settings.filterComplexity.name,
        Settings.filterMinRating.name,
      ]) {
        final setting = sender.settings.setting(name)..enabled = true;
        sender.settings.updateSetting(setting);
      }

      final url = Router.gameNightPermalink(
        sender,
        GameNightLineup(main: _game(263895, 90)),
      );

      // None of the guided-flow filters bloat the shared link.
      for (final name in [
        Settings.filterMinimumTimeToPlay.name,
        Settings.filterMaximumTimeToPlay.name,
        Settings.filterComplexity.name,
        Settings.filterMinRating.name,
        Settings.filterNumberOfPlayers.name,
      ]) {
        expect(
          url,
          isNot(contains('$name=')),
          reason: '$name must not be shared',
        );
      }
      // Mode rides in the path, not a query flag, and the game itself travels.
      expect(url, isNot(contains('gameNightMode')));
      expect(url, contains('/gameNight/teqqles'));
      expect(url, contains('gameNightLineup=0-263895-0-0'));
    },
  );

  test(
    'encoding the home route with items does not double the leading slash',
    () {
      final fragment = UrlFragmentEncoder.encode(
        Router.homeRoute,
        items: Items([Item('teqqles')]),
        settings: Settings.defaultSettings(),
      );

      expect(fragment.startsWith('//'), isFalse);
      expect(fragment, startsWith('/teqqles'));
    },
  );
}
