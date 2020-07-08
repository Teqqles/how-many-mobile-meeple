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
      expect(mySettings.changedSettings, {customPlayerSetting.name: customPlayerSetting});
    });

    test('ignores changes if the setting is disabled', () {
      var mySettings = Settings.defaultSettings();
      var customPlayerSetting = Settings.filterNumberOfPlayers.clone();
      customPlayerSetting.value = 1;
      mySettings.updateSetting(customPlayerSetting);
      expect(mySettings.changedSettings, {});
    });
  });
}