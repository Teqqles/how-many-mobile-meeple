import 'package:flutter/cupertino.dart';
import 'package:how_many_mobile_meeple/model/app_preferences.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/storage/preferences_history.dart';

import 'drawer_heading.dart';
import 'drawer_saved_setting.dart';

class DrawerSettingsColumn {
  final PreferencesHistoryDb historyDb;
  final String drawerName;

  DrawerSettingsColumn(this.drawerName, {this.historyDb}) : super();

  Future<List<Widget>> drawerContent(
      BuildContext context, AppModel model) async {
    List<Widget> fixedDrawerItems = [DrawerHeading(drawerName, context)];
    List<Widget> dynamicDrawerItems = await settingsFromDb(context);
    return fixedDrawerItems + dynamicDrawerItems;
  }

  Future<List<DrawerSavedSetting>> settingsFromDb(BuildContext context) async {
    List<AppPreferences> settings = await historyDb.loadAllPreferences();
    return settings
        .map((pref) =>
            DrawerSavedSetting.preferencesToDrawSettings(pref, context))
        .toList();
  }
}
