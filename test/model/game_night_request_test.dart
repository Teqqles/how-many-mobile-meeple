@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
}
