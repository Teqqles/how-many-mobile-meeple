import 'package:how_many_mobile_meeple/model/item.dart';
import 'package:how_many_mobile_meeple/model/items.dart';
import 'package:how_many_mobile_meeple/model/setting.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';
import 'package:how_many_mobile_meeple/platform/web/url_fragment_extractor.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

class MockUri extends Mock implements Uri {}

main() {
  group('containsModel', () {
    test('returns true when any model data is present', () {
      final mockUri = MockUri();
      when(mockUri.hasFragment).thenReturn(true);
      when(mockUri.fragment).thenReturn('/list/testuser');
      var extractor = UrlFragmentExtractor(mockUri);
      expect(extractor.containsModel(), true);
    });

    test('returns false when fragment exists but does not contain model info', () {
      final mockUri = MockUri();
      when(mockUri.hasFragment).thenReturn(true);
      when(mockUri.fragment).thenReturn('/list');
      var extractor = UrlFragmentExtractor(mockUri);
      expect(extractor.containsModel(), false);
    });

    test('returns false when no fragment exists', () {
      final mockUri = MockUri();
      when(mockUri.hasFragment).thenReturn(false);
      var extractor = UrlFragmentExtractor(mockUri);
      expect(extractor.containsModel(), false);
    });
  });

  var expectedItems = Items([Item("testuser"), Item("1234"), Item("testuser2")]);
  var urlItems = expectedItems.itemList.map((item) => item.name).join("+");

  group('extractItems', () {
    test('is empty if fragment not present', () {
      final mockUri = MockUri();

      when(mockUri.hasFragment).thenReturn(false);

      var extractor = UrlFragmentExtractor(mockUri);
      expect(extractor.extractItems(), Items([]));
    });

    test('applies all items in the uri fragment', () {
      final mockUri = MockUri();

      when(mockUri.hasFragment).thenReturn(true);
      when(mockUri.fragment).thenReturn("/list/$urlItems");

      var extractor = UrlFragmentExtractor(mockUri);
      expect(extractor.extractItems(), expectedItems);
    });

    test('ignores query parameters', () {
      final mockUri = MockUri();

      when(mockUri.hasFragment).thenReturn(true);
      when(mockUri.fragment).thenReturn("/list/$urlItems?moo");

      var extractor = UrlFragmentExtractor(mockUri);
      expect(extractor.extractItems(), expectedItems);
    });
  });

  var customExpectedSettings = Settings({
    "setting1": Setting("setting1", value: "value1", enabled: true),
    "setting2": Setting("setting2", value: "value2", enabled: true)
  });
  var urlSettings = customExpectedSettings
      .allSettings.values
      .map((setting) => "${setting.name}=${setting.value}")
      .join("&");
  var expectedSettings = Settings.defaultSettings();
  var defaults = Settings.defaultSettings();
  expectedSettings.updateAllSettings(customExpectedSettings);

  group('extractSettings', () {
    test('returns default if fragment not present', () {
      final mockUri = MockUri();

      when(mockUri.hasFragment).thenReturn(false);

      var extractor = UrlFragmentExtractor(mockUri);
      expect(extractor.extractSettings(), defaults);
    });

    test('applies all settings in the uri fragment', () {
      final mockUri = MockUri();

      when(mockUri.hasFragment).thenReturn(true);
      when(mockUri.fragment).thenReturn("/list?$urlSettings");

      var extractor = UrlFragmentExtractor(mockUri);
      expect(extractor.extractSettings(), expectedSettings);
    });

    test('ignores items', () {
      final mockUri = MockUri();

      when(mockUri.hasFragment).thenReturn(true);
      when(mockUri.fragment).thenReturn("/list/user1?$urlSettings");

      var extractor = UrlFragmentExtractor(mockUri);
      expect(extractor.extractSettings(), expectedSettings);
    });

    test('overrides existing settings if present in query', () {
      final mockUri = MockUri();
      var expectedSettings = Settings.defaultSettings();
      var updatedSetting = Settings.filterNumberOfPlayers;
      updatedSetting.value = 12;
      updatedSetting.enabled = true;
      expectedSettings.updateSetting(updatedSetting);

      when(mockUri.hasFragment).thenReturn(true);
      when(mockUri.fragment).thenReturn("/list?${updatedSetting.name}=${updatedSetting.value}");

      var extractor = UrlFragmentExtractor(mockUri);
      expect(extractor.extractSettings(), expectedSettings);
    });

    test('url decodes symbols in value', () {
      final mockUri = MockUri();
      var expectedSettings = Settings.defaultSettings();
      var updatedSetting = Settings.filterMechanics;
      updatedSetting.value = ["Card Drafting"];
      updatedSetting.enabled = true;
      expectedSettings.updateSetting(updatedSetting);

      when(mockUri.hasFragment).thenReturn(true);
      when(mockUri.fragment).thenReturn("/list?${updatedSetting.name}=${Uri.encodeComponent(updatedSetting.value.toString())}");

      var extractor = UrlFragmentExtractor(mockUri);
      expect(extractor.extractSettings(), expectedSettings);
    });

  });
}
