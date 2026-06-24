import 'package:flutter/material.dart';
import 'package:how_many_mobile_meeple/model/app_preferences.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/storage/storage_factory.dart';
import 'package:how_many_mobile_meeple/platform/router.dart' as r;

import '../app_common.dart';

class DrawerSavedSetting extends Container {
  final String preferencesTitle;
  final AppPreferences preferences;

  DrawerSavedSetting(
      this.preferencesTitle, this.preferences, BuildContext context,
      {int index = 0})
      : super(
          padding:
              const EdgeInsets.only(top: 12, bottom: 12, left: 8, right: 8),
          decoration: BoxDecoration(
              color: index % 2 == 0
                  ? Theme.of(context).highlightColor
                  : Colors.white,
              border: Border(
                  bottom: BorderSide(
                      width: 1,
                      color: index % 2 == 0
                          ? Theme.of(context).highlightColor
                          : Colors.white))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              InkWell(
                child: Text(
                  preferencesTitle,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                      fontSize: 13, decoration: TextDecoration.underline),
                ),
                onTap: () async {
                  var model = AppModel.of(context, listen: false);

                  // Capture navigator before async operations
                  final navigator = Navigator.of(context);

                  await model.replaceItems(preferences.items);
                  await model.replaceSettings(preferences.settings);
                  model.refreshState();
                  navigator.pop();

                  // Always show settings summary after loading saved settings
                  Future.delayed(Duration(milliseconds: 300), () {
                    navigator.pushNamed(r.Router.settingsRoute);
                  });
                }, // id},
              ),
              IconButton(
                icon: Icon(
                  Icons.delete,
                  size: AppCommon.standardIconSize,
                  color: Theme.of(context).colorScheme.error,
                ),
                onPressed: () {
                  if (preferences.id == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Cannot delete unsaved preference')),
                    );
                    return;
                  }
                  var model = AppModel.of(context, listen: false);
                  var db = StorageFactory.getPreferencesHistory();
                  db.deletePreference(preferences.id!);
                  model.refreshState();
                },
              ),
            ],
          ),
        );

  static DrawerSavedSetting preferencesToDrawerSettings(
      AppPreferences preferences, BuildContext context,
      {int index = 0}) {
    return DrawerSavedSetting(preferences.title, preferences, context,
        index: index);
  }
}
