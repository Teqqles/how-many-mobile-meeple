import 'package:how_many_mobile_meeple/storage/stored_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class StorageFactory {
  static Future<StoredPreferences> getStoredPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return StoredPreferences(prefs);
  }
}
