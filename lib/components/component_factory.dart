import 'package:how_many_mobile_meeple/storage/storage_factory.dart';
import 'drawer_settings_column.dart';

abstract class ComponentFactory {
  static Future<DrawerSettingsColumn> getDrawerSettingsColumn(
      String drawerName) async {
    return DrawerSettingsColumn(drawerName,
        historyDb: StorageFactory.getPreferencesHistory());
  }
}
