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

  test('an enabled game-night player count filters the pool', () {
    final model = AppModel();
    final players = model.settings.setting(Settings.gameNightPlayerCount.name)
      ..value = 6
      ..enabled = true;
    model.settings.updateSetting(players);

    final headers = model.buildGameNightRequest().headers;

    expect(headers[Settings.filterNumberOfPlayers.header], '6');
  });

  test('a disabled game-night player count leaves the pool unfiltered', () {
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

  test('permalink settings turn on game night mode and encode the lineup', () {
    final model = AppModel();
    final lineup = GameNightLineup(filler: _game(12, 20), main: _game(45, 90));

    final settings = model.gameNightPermalinkSettings(lineup);

    expect(settings.setting(Settings.gameNightMode.name).getBool(), isTrue);
    expect(
      settings.setting(Settings.gameNightLineup.name).getString(),
      '12-45-0-0',
    );
    expect(settings.setting(Settings.gameNightLineup.name).enabled, isTrue);
  });

  test('building permalink settings does not mutate the live settings', () {
    final model = AppModel();

    model.gameNightPermalinkSettings(GameNightLineup(main: _game(45, 90)));

    expect(
      model.settings.setting(Settings.gameNightMode.name).getBool(),
      false,
    );
    expect(
      model.settings.setting(Settings.gameNightLineup.name).enabled,
      isFalse,
    );
  });
}
