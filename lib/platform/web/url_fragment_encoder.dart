import 'package:how_many_mobile_meeple/model/items.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';

class UrlFragmentEncoder {
  static String encode(
    String name, {
    required Items items,
    required Settings settings,
  }) {
    var encodedItems = items.itemList
        .map((item) => item.toUrlToken())
        .join("+");
    var encodedSettings = settings.changedSettings.values
        .map((setting) => "${setting.name}=${setting.value}")
        .join("&");
    var encodedFragment = name;
    if (encodedItems.isNotEmpty) {
      // The home route is "/", so blindly appending "/items" yields "//items".
      // Parsed as a Uri that leading "//" reads the collection as an authority,
      // and a refresh - which routes on the Uri path - then drops it, losing
      // the sources a shared link carries (e.g. a Game Night permalink).
      final separator = name.endsWith("/") ? "" : "/";
      encodedFragment += "$separator$encodedItems";
    }
    if (encodedSettings.isNotEmpty) encodedFragment += "?$encodedSettings";
    return encodedFragment;
  }
}
