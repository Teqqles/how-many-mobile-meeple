import 'package:how_many_mobile_meeple/model/items.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';

class UrlFragmentEncoder {
  static String encode(String name, {Items items, Settings settings}) {
    var encodedItems = items != null ? items.itemList.map((item) => item.name).join("+") : '';
    var encodedSettings = settings?.changedSettings != null ? settings.changedSettings.values.map((setting) => "${setting.name}=${setting.value}").join("&") : '';
    var encodedFragment = name;
    if (encodedItems.isNotEmpty)
      encodedFragment += "/$encodedItems";
    if (encodedSettings.isNotEmpty)
      encodedFragment += "?$encodedSettings";
    return encodedFragment;
  }
}