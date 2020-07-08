
import 'package:how_many_mobile_meeple/model/item.dart';
import 'package:how_many_mobile_meeple/model/items.dart';
import 'package:how_many_mobile_meeple/model/setting.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';
import 'package:how_many_mobile_meeple/platform/router.dart';

class UrlFragmentExtractor {

  Uri uri;
  bool hasModelData = false;

  UrlFragmentExtractor(Uri uri) {
    this.uri = uri;
    hasModelData = uri.hasFragment && !Router.routeList.contains(uri.fragment);
  }

  bool containsModel() {
    return hasModelData;
  }

  Items extractItems() {
    if (!containsModel()) {
      return Items([]);
    }
    var potentialEncodedItems = _removePageTypeFromFragment(uri.fragment);
    var itemsFromString = potentialEncodedItems.split("+").map((strItem) => Item(strItem)).toList();
    return Items(itemsFromString);
  }

  String _removePageTypeFromFragment(String fragment) {
    var lastPathIndex = fragment.lastIndexOf(new RegExp(r'/'));
    var firstQueryIndex = _calculateQueryPosition(fragment);
    if (firstQueryIndex > -1) {
      return fragment.substring(lastPathIndex+1, firstQueryIndex);
    }
    return fragment.substring(lastPathIndex+1);
  }
  
  int _calculateQueryPosition(String fragment) {
    return fragment.indexOf(new RegExp(r'\?'));
  }

  Settings extractSettings() {
    var settings = Settings.defaultSettings();
    if (!containsModel()) {
      return settings;
    }
    print(uri.fragment);
    var firstQueryIndex = _calculateQueryPosition(uri.fragment);
    var potentialEncodedSettings = uri.fragment.substring(firstQueryIndex+1);
    var settingsFromString = potentialEncodedSettings.split("&");
    var newSettings = _mapSettingsFromFragments(settingsFromString);
    settings.updateAllSettings(newSettings);
    return settings;
  }

  Settings _mapSettingsFromFragments(List<String> settingsFromString) {
    var defaults = Settings.defaultSettings();
    var settings = Settings({});
    for (var settingStr in settingsFromString) {
      var parts = settingStr.split("=");
      if (parts.length == 2) {
        var settingHeader = defaults.setting(parts[0])?.header;
        var setting = Setting(parts[0], value: Uri.decodeComponent(parts[1]), header: settingHeader, enabled: true);
        settings.updateSetting(setting);
      }
    }
    return settings;
  }

}