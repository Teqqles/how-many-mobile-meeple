@Tags(['unit'])
library;

import 'package:how_many_mobile_meeple/model/item.dart';
import 'package:how_many_mobile_meeple/model/items.dart';
import 'package:how_many_mobile_meeple/model/setting.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';
import 'package:how_many_mobile_meeple/platform/web/url_fragment_extractor.dart';
import 'package:test/test.dart';

// Under clean-path routing the encoded model rides in the Uri path (plus
// query), which go_router hands over verbatim - so the extractor is driven
// straight from that location string rather than a hash fragment.
main() {
  group('containsModel', () {
    test('returns true when any model data is present', () {
      final extractor = UrlFragmentExtractor.fromLocation('/list/testuser');
      expect(extractor.containsModel(), true);
    });

    test(
      'returns false when fragment exists but does not contain model info',
      () {
        final extractor = UrlFragmentExtractor.fromLocation('/list');
        expect(extractor.containsModel(), false);
      },
    );

    test('returns false when no fragment exists', () {
      final extractor = UrlFragmentExtractor.fromLocation('');
      expect(extractor.containsModel(), false);
    });

    test('returns false for a game detail deep link', () {
      // The trailing segment is a game id, not a source, so this fragment
      // encodes no model - stored parameters should load instead.
      final extractor = UrlFragmentExtractor.fromLocation(
        '/game/Gloomhaven/174430',
      );
      expect(extractor.containsModel(), false);
    });

    test('returns false for the bare game route', () {
      final extractor = UrlFragmentExtractor.fromLocation('/game');
      expect(extractor.containsModel(), false);
    });

    test('returns false for a shelf of shame deep link', () {
      // The trailing segment is the collection owner's username, consumed by
      // the page's route parameter - not an encoded model. Treating it as one
      // seeds a bogus source and churns state, spinning the page in a reload
      // loop that spams the collection API.
      final extractor = UrlFragmentExtractor.fromLocation(
        '/shelf-of-shame/teqqles',
      );
      expect(extractor.containsModel(), false);
    });

    test('returns false for the bare shelf of shame route', () {
      final extractor = UrlFragmentExtractor.fromLocation('/shelf-of-shame');
      expect(extractor.containsModel(), false);
    });

    test('returns true for a Game Night deep link', () {
      // The collection travels in the path like any other model link.
      final extractor = UrlFragmentExtractor.fromLocation('/gameNight/teqqles');
      expect(extractor.containsModel(), true);
    });
  });

  group('game night path form', () {
    test('extracts the collection from a /gameNight link', () {
      final extractor = UrlFragmentExtractor.fromLocation(
        '/gameNight/teqqles?gameNightLineup=1-2-3-0',
      );
      expect(extractor.extractItems(), Items([Item('teqqles')]));
    });

    test('turns on game night mode from the /gameNight path prefix', () {
      final settings = UrlFragmentExtractor.fromLocation(
        '/gameNight/teqqles?gameNightLineup=1-2-3-0',
      ).extractSettings();
      final mode = settings.setting(Settings.gameNightMode.name);
      expect(mode.getBool(), isTrue);
      expect(mode.enabled, isTrue);
      // The query still rides along.
      expect(
        settings.setting(Settings.gameNightLineup.name).getString(),
        '1-2-3-0',
      );
    });

    test('leaves game night mode off for an ordinary collection link', () {
      final settings = UrlFragmentExtractor.fromLocation('/list/teqqles')
          .extractSettings();
      expect(settings.setting(Settings.gameNightMode.name).getBool(), isFalse);
    });
  });

  var expectedItems = Items([
    Item("testuser"),
    Item("1234"),
    Item("testuser2"),
  ]);
  var urlItems = expectedItems.itemList.map((item) => item.name).join("+");

  group('extractItems', () {
    test('is empty if fragment not present', () {
      final extractor = UrlFragmentExtractor.fromLocation('');
      expect(extractor.extractItems(), Items([]));
    });

    test('applies all items in the uri fragment', () {
      final extractor = UrlFragmentExtractor.fromLocation("/list/$urlItems");
      expect(extractor.extractItems(), expectedItems);
    });

    test('restores a bracketed hotList token as a hotList source', () {
      final extractor = UrlFragmentExtractor.fromLocation("/random/[trending]");
      final items = extractor.extractItems();
      expect(items.itemList.length, 1);
      expect(items.itemList.first.name, 'trending');
      expect(items.itemList.first.itemType, ItemType.hotList);
    });

    test('restores a percent-encoded hotList token as a hotList source', () {
      // The browser encodes the brackets, so the real fragment looks like this.
      final extractor = UrlFragmentExtractor.fromLocation(
        "/random/%5Btrending%5D",
      );
      final items = extractor.extractItems();
      expect(items.itemList.length, 1);
      expect(items.itemList.first.name, 'trending');
      expect(items.itemList.first.itemType, ItemType.hotList);
    });

    test('restores a mix of hotList and collection tokens', () {
      final extractor = UrlFragmentExtractor.fromLocation(
        "/list/[trending]+teqqles",
      );
      expect(
        extractor.extractItems(),
        Items([Item('trending', itemType: ItemType.hotList), Item('teqqles')]),
      );
    });

    test('ignores query parameters', () {
      final extractor = UrlFragmentExtractor.fromLocation(
        "/list/$urlItems?moo",
      );
      expect(extractor.extractItems(), expectedItems);
    });

    test('numeric item in fragment is extracted as geeklist type', () {
      final extractor = UrlFragmentExtractor.fromLocation("/list/12345");
      var items = extractor.extractItems();

      expect(items.itemList.length, 1);
      expect(items.itemList.first.name, '12345');
      expect(items.itemList.first.itemType, ItemType.geekList);
    });

    test('alpha item in fragment is extracted as collection type', () {
      final extractor = UrlFragmentExtractor.fromLocation("/list/testuser");
      var items = extractor.extractItems();

      expect(items.itemList.first.itemType, ItemType.collection);
    });

    test(
      'mixed geeklist and collection items are extracted with correct types',
      () {
        final extractor = UrlFragmentExtractor.fromLocation(
          "/list/testuser+12345",
        );
        var items = extractor.extractItems();

        expect(items.itemList.length, 2);
        expect(items.itemList[0].itemType, ItemType.collection);
        expect(items.itemList[1].itemType, ItemType.geekList);
      },
    );
  });

  var customExpectedSettings = Settings({
    "setting1": Setting("setting1", value: "value1", enabled: true),
    "setting2": Setting("setting2", value: "value2", enabled: true),
  });
  var urlSettings = customExpectedSettings.allSettings.values
      .map((setting) => "${setting.name}=${setting.value}")
      .join("&");
  var expectedSettings = Settings.defaultSettings();
  var defaults = Settings.defaultSettings();
  expectedSettings.updateAllSettings(customExpectedSettings);

  group('extractSettings', () {
    test('returns default if fragment not present', () {
      final extractor = UrlFragmentExtractor.fromLocation('');
      expect(extractor.extractSettings(), defaults);
    });

    test('applies all settings in the uri fragment', () {
      final extractor = UrlFragmentExtractor.fromLocation("/list?$urlSettings");
      expect(extractor.extractSettings(), expectedSettings);
    });

    test('ignores items', () {
      final extractor = UrlFragmentExtractor.fromLocation(
        "/list/user1?$urlSettings",
      );
      expect(extractor.extractSettings(), expectedSettings);
    });

    test('overrides existing settings if present in query', () {
      var expectedSettings = Settings.defaultSettings();
      var updatedSetting = Settings.filterNumberOfPlayers;
      updatedSetting.value = 12;
      updatedSetting.enabled = true;
      expectedSettings.updateSetting(updatedSetting);

      final extractor = UrlFragmentExtractor.fromLocation(
        "/list?${updatedSetting.name}=${updatedSetting.value}",
      );
      expect(extractor.extractSettings(), expectedSettings);
    });

    test('url decodes symbols in value', () {
      var expectedSettings = Settings.defaultSettings();
      var updatedSetting = Settings.filterMechanics;
      updatedSetting.value = ["Card Drafting"];
      updatedSetting.enabled = true;
      expectedSettings.updateSetting(updatedSetting);

      final extractor = UrlFragmentExtractor.fromLocation(
        "/list?${updatedSetting.name}=${Uri.encodeComponent(updatedSetting.value.toString())}",
      );
      expect(extractor.extractSettings(), expectedSettings);
    });
  });
}
