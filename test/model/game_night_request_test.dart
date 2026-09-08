@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:how_many_mobile_meeple/model/game.dart';
import 'package:how_many_mobile_meeple/model/game_night.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

void _enable(AppModel model, String name) {
  final setting = model.settings.setting(name)..enabled = true;
  model.settings.updateSetting(setting);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('game night request ignores the guided-flow filters', () {
    final model = AppModel();
    _enable(model, Settings.filterMinimumTimeToPlay.name);
    _enable(model, Settings.filterMaximumTimeToPlay.name);
    _enable(model, Settings.filterNumberOfPlayers.name);
    _enable(model, Settings.filterComplexity.name);
    _enable(model, Settings.filterMinRating.name);

    final headers = model.buildGameNightRequest().headers;

    // The evening budget governs playtime and no guided-flow filter leaks in,
    // so the pool starts from the whole collection.
    for (final header in [
      Settings.filterMinimumTimeToPlay.header,
      Settings.filterMaximumTimeToPlay.header,
      Settings.filterNumberOfPlayers.header,
      Settings.filterComplexity.header,
      Settings.filterMinRating.header,
    ]) {
      expect(headers.containsKey(header), isFalse);
    }
  });

  test('an enabled game-night player count is not sent to the server', () {
    final model = AppModel();
    final players = model.settings.setting(Settings.gameNightPlayerCount.name)
      ..value = 6
      ..enabled = true;
    model.settings.updateSetting(players);

    final headers = model.buildGameNightRequest().headers;

    // Player count is applied locally in the view so the fetched pool stays
    // whole; a shared lineup can then pin a game the count would exclude.
    expect(headers.containsKey(Settings.filterNumberOfPlayers.header), isFalse);
  });

  test('the game-night pool is fetched unfiltered by player count', () {
    final model = AppModel();

    final headers = model.buildGameNightRequest().headers;

    expect(headers.containsKey(Settings.filterNumberOfPlayers.header), isFalse);
  });

  test('the game night request whitelists mechanics for local filtering', () {
    final model = AppModel();

    final headers = model.buildGameNightRequest().headers;
    final whitelist = headers[Settings.fieldsToReturnFromApi.header]!.split(
      ',',
    );

    expect(whitelist, contains('mechanics'));
  });

  test(
    'building the game night request does not mutate the model settings',
    () {
      final model = AppModel();
      _enable(model, Settings.filterMaximumTimeToPlay.name);

      model.buildGameNightRequest();

      final normalHeaders = model.buildRequest().headers;
      expect(
        normalHeaders.containsKey(Settings.filterMaximumTimeToPlay.header),
        isTrue,
      );
    },
  );

  test('permalink settings encode the lineup', () {
    final model = AppModel();
    final lineup = GameNightLineup(filler: _game(12, 20), main: _game(45, 90));

    final settings = model.gameNightPermalinkSettings(lineup);

    expect(
      settings.setting(Settings.gameNightLineup.name).getString(),
      '12-45-0-0',
    );
    expect(settings.setting(Settings.gameNightLineup.name).enabled, isTrue);
  });

  test('permalink settings leave game night mode to the link path', () {
    final model = AppModel();

    final settings = model.gameNightPermalinkSettings(
      GameNightLineup(main: _game(45, 90)),
    );

    // Mode rides in the `/gameNight` path prefix, so it is not a URL setting;
    // it stays at its (disabled) default here.
    expect(settings.setting(Settings.gameNightMode.name).getBool(), isFalse);
  });

  test('building permalink settings does not mutate the live settings', () {
    final model = AppModel();

    model.gameNightPermalinkSettings(GameNightLineup(main: _game(45, 90)));

    expect(
      model.settings.setting(Settings.gameNightLineup.name).enabled,
      isFalse,
    );
  });
}
