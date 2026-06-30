// coverage:ignore-file
import 'drawer_settings_column.dart';

abstract class ComponentFactory {
  static DrawerSettingsColumn getDrawerSettingsColumn(String drawerName) {
    return DrawerSettingsColumn(drawerName);
  }
}
