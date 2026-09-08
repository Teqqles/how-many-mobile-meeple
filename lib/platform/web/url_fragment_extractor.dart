import 'package:how_many_mobile_meeple/model/item.dart';
import 'package:how_many_mobile_meeple/model/items.dart';
import 'package:how_many_mobile_meeple/model/setting.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';
import 'package:how_many_mobile_meeple/platform/router.dart';

class UrlFragmentExtractor {
  /// The route location as a clean path plus query, e.g.
  /// `/gameNight/teqqles?maxPlayers=4`. Under clean-path URL routing this is
  /// what carries the encoded model - the old hash fragment is gone.
  late final String location;
  bool hasModelData = false;

  UrlFragmentExtractor(Uri uri) : this.fromLocation(_locationOf(uri));

  /// Builds an extractor straight from a go_router location string (what
  /// [GoRouterState.uri] yields for an in-app navigation), bypassing [Uri.base].
  UrlFragmentExtractor.fromLocation(this.location) {
    hasModelData =
        location.isNotEmpty &&
        !Router.routeList.contains(location) &&
        !_isGameDetailFragment(location) &&
        !_isShelfOfShameFragment(location);
  }

  /// Clean-path routing only exists on the web, where [Uri.base] is an
  /// http(s) URL whose path is the app route. Off the web (e.g. VM tests)
  /// [Uri.base] is the `file:` working directory, whose path is not a route -
  /// treating it as one would seed garbage sources, so it carries no location.
  static String _locationOf(Uri uri) {
    if (!uri.isScheme('http') && !uri.isScheme('https')) return '';
    return uri.hasQuery ? '${uri.path}?${uri.query}' : uri.path;
  }

  /// A game detail deep link (e.g. `/game/Gloomhaven/174430`) encodes no
  /// sources or settings - the trailing segment is a game id, not a collection.
  /// Treating it as a model would wire that id in as a source, so we exclude it
  /// and let stored parameters load instead.
  bool _isGameDetailFragment(String location) =>
      location == Router.gameDetailRoute ||
      location.startsWith('${Router.gameDetailRoute}/');

  /// A shelf of shame deep link (e.g. `/shelf-of-shame/teqqles`) carries the
  /// collection owner's username as a route parameter, which the page consumes
  /// directly - it is not an encoded model. Treating it as one seeds the
  /// username as a bogus source and churns model state, spinning the page in a
  /// reload loop that hammers the collection API, so we exclude it here.
  bool _isShelfOfShameFragment(String location) =>
      location == Router.shelfOfShameRoute ||
      location.startsWith('${Router.shelfOfShameRoute}/');

  /// A Game Night deep link (e.g. `/gameNight/teqqles`). The `/gameNight` prefix
  /// carries the collection like any other model link, but also signals Game
  /// Night mode - which [extractSettings] turns on - in place of a query flag.
  bool _isGameNightFragment(String location) =>
      location == Router.gameNightRoute ||
      location.startsWith('${Router.gameNightRoute}/');

  bool containsModel() {
    return hasModelData;
  }

  Items extractItems() {
    if (!containsModel()) {
      return Items([]);
    }
    var potentialEncodedItems = _removePageTypeFromLocation(location);
    var itemsFromString = potentialEncodedItems
        .split("+")
        .map((strItem) => Item.fromUrlToken(strItem))
        .toList();
    return Items(itemsFromString);
  }

  String _removePageTypeFromLocation(String location) {
    var lastPathIndex = location.lastIndexOf(new RegExp(r'/'));
    var firstQueryIndex = _calculateQueryPosition(location);
    if (firstQueryIndex > -1) {
      return location.substring(lastPathIndex + 1, firstQueryIndex);
    }
    return location.substring(lastPathIndex + 1);
  }

  int _calculateQueryPosition(String location) {
    return location.indexOf(new RegExp(r'\?'));
  }

  Settings extractSettings() {
    var settings = Settings.defaultSettings();
    if (!containsModel()) {
      return settings;
    }
    var firstQueryIndex = _calculateQueryPosition(location);
    if (firstQueryIndex > -1) {
      var potentialEncodedSettings = location.substring(firstQueryIndex + 1);
      var settingsFromString = potentialEncodedSettings.split("&");
      var newSettings = _mapSettingsFromFragments(settingsFromString);
      settings.updateAllSettings(newSettings);
    }
    // The `/gameNight` path prefix stands in for a `gameNightMode=true` query
    // flag, so turn the mode on from the route rather than the query string.
    if (_isGameNightFragment(location)) {
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
