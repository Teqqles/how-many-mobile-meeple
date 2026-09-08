import 'package:how_many_mobile_meeple/model/item.dart';
import 'package:how_many_mobile_meeple/model/items.dart';
import 'package:how_many_mobile_meeple/model/setting.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';
import 'package:how_many_mobile_meeple/platform/router.dart';

class UrlFragmentExtractor {
  late Uri uri;
  bool hasModelData = false;

  UrlFragmentExtractor(Uri uri) {
    this.uri = uri;
    hasModelData =
        uri.hasFragment &&
        !Router.routeList.contains(uri.fragment) &&
        !_isGameDetailFragment(uri.fragment) &&
        !_isShelfOfShameFragment(uri.fragment);
  }

  /// A game detail deep link (e.g. `/game/Gloomhaven/174430`) encodes no
  /// sources or settings - the trailing segment is a game id, not a collection.
  /// Treating it as a model would wire that id in as a source, so we exclude it
  /// and let stored parameters load instead.
  bool _isGameDetailFragment(String fragment) =>
      fragment == Router.gameDetailRoute ||
      fragment.startsWith('${Router.gameDetailRoute}/');

  /// A shelf of shame deep link (e.g. `/shelf-of-shame/teqqles`) carries the
  /// collection owner's username as a route parameter, which the page consumes
  /// directly - it is not an encoded model. Treating it as one seeds the
  /// username as a bogus source and churns model state, spinning the page in a
  /// reload loop that hammers the collection API, so we exclude it here.
  bool _isShelfOfShameFragment(String fragment) =>
      fragment == Router.shelfOfShameRoute ||
      fragment.startsWith('${Router.shelfOfShameRoute}/');

  /// A Game Night deep link (e.g. `/gameNight/teqqles`). The `/gameNight` prefix
  /// carries the collection like any other model link, but also signals Game
  /// Night mode - which [extractSettings] turns on - in place of a query flag.
  bool _isGameNightFragment(String fragment) =>
      fragment == Router.gameNightRoute ||
      fragment.startsWith('${Router.gameNightRoute}/');

  bool containsModel() {
    return hasModelData;
  }

  Items extractItems() {
    if (!containsModel()) {
      return Items([]);
    }
    var potentialEncodedItems = _removePageTypeFromFragment(uri.fragment);
    var itemsFromString = potentialEncodedItems
        .split("+")
        .map((strItem) => Item.fromUrlToken(strItem))
        .toList();
    return Items(itemsFromString);
  }

  String _removePageTypeFromFragment(String fragment) {
    var lastPathIndex = fragment.lastIndexOf(new RegExp(r'/'));
    var firstQueryIndex = _calculateQueryPosition(fragment);
    if (firstQueryIndex > -1) {
      return fragment.substring(lastPathIndex + 1, firstQueryIndex);
    }
    return fragment.substring(lastPathIndex + 1);
  }

  int _calculateQueryPosition(String fragment) {
    return fragment.indexOf(new RegExp(r'\?'));
  }

  Settings extractSettings() {
    var settings = Settings.defaultSettings();
    if (!containsModel()) {
      return settings;
    }
    var firstQueryIndex = _calculateQueryPosition(uri.fragment);
    if (firstQueryIndex > -1) {
      var potentialEncodedSettings = uri.fragment.substring(
        firstQueryIndex + 1,
      );
      var settingsFromString = potentialEncodedSettings.split("&");
      var newSettings = _mapSettingsFromFragments(settingsFromString);
      settings.updateAllSettings(newSettings);
    }
    // The `/gameNight` path prefix stands in for a `gameNightMode=true` query
    // flag, so turn the mode on from the route rather than the query string.
    if (_isGameNightFragment(uri.fragment)) {
      final mode = settings.setting(Settings.gameNightMode.name)
        ..value = true
        ..enabled = true;
      settings.updateSetting(mode);
    }
    return settings;
  }

  Settings _mapSettingsFromFragments(List<String> settingsFromString) {
    var defaults = Settings.defaultSettings();
    var settings = Settings({});
    for (var settingStr in settingsFromString) {
      var parts = settingStr.split("=");
      if (parts.length == 2) {
        var settingHeader = defaults.setting(parts[0]).header;
        var setting = Setting(
          parts[0],
          value: Uri.decodeComponent(parts[1]),
          header: settingHeader,
          enabled: true,
        );
        settings.updateSetting(setting);
      }
    }
    return settings;
  }
}
