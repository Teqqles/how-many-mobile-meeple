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
