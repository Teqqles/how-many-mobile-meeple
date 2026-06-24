import 'package:flutter/cupertino.dart';
import 'package:how_many_mobile_meeple/model/app_preferences.dart';
import 'package:how_many_mobile_meeple/model/model.dart';

import 'drawer_heading.dart';
import 'drawer_saved_setting.dart';

class DrawerSettingsColumn {
  final String drawerName;

  DrawerSettingsColumn(this.drawerName);

  Future<List<Widget>> drawerContent(
      BuildContext context, AppModel model, int startIndex) async {
    List<Widget> fixedDrawerItems = [DrawerHeading(drawerName, context)];
    List<Widget> dynamicDrawerItems =
        await settingsFromModel(context, model, startIndex);
    return fixedDrawerItems + dynamicDrawerItems;
  }

  Future<List<DrawerSavedSetting>> settingsFromModel(
      BuildContext context, AppModel model, int startIndex) async {
    List<AppPreferences> settings = await model.getSavedPreferences();
    return settings
        .asMap()
        .entries
        .map((entry) => DrawerSavedSetting.preferencesToDrawerSettings(
            entry.value, context,
            index: startIndex + entry.key))
        .toList();
  }
}
