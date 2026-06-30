@Tags(['unit'])
library;

import 'package:how_many_mobile_meeple/model/settings.dart';
import 'package:test/test.dart';

main() {
  group('changedSettings', () {
    test('returns no settings if settings identical to default', () {
      var mySettings = Settings.defaultSettings();
      expect(mySettings.changedSettings, {});
    });
    test('returns only settings changed from default', () {
      var mySettings = Settings.defaultSettings();
      var customPlayerSetting = Settings.filterNumberOfPlayers.clone();
      customPlayerSetting.enabled = true;
      mySettings.updateSetting(customPlayerSetting);
      expect(mySettings.changedSettings,
          {customPlayerSetting.name: customPlayerSetting});
    });

    test('ignores changes if the setting is disabled', () {
      var mySettings = Settings.defaultSettings();
      var customPlayerSetting = Settings.filterNumberOfPlayers.clone();
      customPlayerSetting.value = 1;
      mySettings.updateSetting(customPlayerSetting);
      expect(mySettings.changedSettings, {});
    });
  });

  group('inferMinTime', () {
    test('returns half of the given max time', () {
      expect(Settings.inferMinTime(60), 30);
      expect(Settings.inferMinTime(90), 45);
    });

    test('floors odd values', () {
      expect(Settings.inferMinTime(45), 22);
      expect(Settings.inferMinTime(31), 15);
    });

    test('returns zero for zero input', () {
      expect(Settings.inferMinTime(0), 0);
    });

    test('returns zero for input of 1', () {
      expect(Settings.inferMinTime(1), 0);
    });

    test('handles large values', () {
      expect(Settings.inferMinTime(600), 300);
    });
  });

  group('setting()', () {
    test('returns existing setting when key exists', () {
      var mySettings = Settings.defaultSettings();
      var playerSetting = mySettings.setting('numberOfPlayers');
      expect(playerSetting.name, 'numberOfPlayers');
      expect(playerSetting.value, 5);
    });

    test('returns default setting when key exists in defaults but not current',
        () {
      var mySettings = Settings({});
      var playerSetting = mySettings.setting('numberOfPlayers');
      expect(playerSetting.name, 'numberOfPlayers');
      expect(playerSetting.value, 5);
    });

    test('returns disabled placeholder for unknown keys instead of throwing',
        () {
      var mySettings = Settings.defaultSettings();
      var unknownSetting = mySettings.setting('unknownSettingFromOldUrl');
      expect(unknownSetting.name, 'unknownSettingFromOldUrl');
      expect(unknownSetting.enabled, false);
      expect(unknownSetting.value, null);
      expect(unknownSetting.header, null);
    });

    test('handles old URL settings gracefully', () {
      // Simulate loading settings from old URL with removed setting
      var mySettings = Settings({});
      expect(() => mySettings.setting('removedSetting'), returnsNormally);
      var removedSetting = mySettings.setting('removedSetting');
      expect(removedSetting.enabled, false);
    });
  });
}
