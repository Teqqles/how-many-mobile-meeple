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

  test('game night request drops the per-game duration filters', () {
    final model = AppModel();
    _enable(model, Settings.filterMinimumTimeToPlay.name);
    _enable(model, Settings.filterMaximumTimeToPlay.name);
    _enable(model, Settings.filterNumberOfPlayers.name);

    final headers = model.buildGameNightRequest().headers;

    expect(
      headers.containsKey(Settings.filterMinimumTimeToPlay.header),
      isFalse,
    );
    expect(
      headers.containsKey(Settings.filterMaximumTimeToPlay.header),
      isFalse,
    );
    // Non-duration filters still shape the pool.
    expect(headers.containsKey(Settings.filterNumberOfPlayers.header), isTrue);
  });

  test('stripping duration filters does not mutate the model settings', () {
    final model = AppModel();
    _enable(model, Settings.filterMaximumTimeToPlay.name);

    model.buildGameNightRequest();

    final normalHeaders = model.buildRequest().headers;
    expect(
      normalHeaders.containsKey(Settings.filterMaximumTimeToPlay.header),
      isTrue,
    );
  });

  test('permalink settings turn on game night mode and encode the lineup', () {
    final model = AppModel();
    final lineup = GameNightLineup(filler: _game(12, 20), main: _game(45, 90));

    final settings = model.gameNightPermalinkSettings(lineup);

    expect(settings.setting(Settings.gameNightMode.name).getBool(), isTrue);
    expect(
      settings.setting(Settings.gameNightLineup.name).getString(),
      '12-45-0',
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
