import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:how_many_mobile_meeple/model/app_preferences.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/storage/preferences_history.dart';

class DrawerSavedSetting extends Container {

  static var iconSize = 30.0;

  final String preferencesTitle;
  final AppPreferences preferences;

  DrawerSavedSetting(
      this.preferencesTitle, this.preferences, BuildContext context)
      : super(
          padding: EdgeInsets.only(top: 12, bottom: 12, left: 8, right: 8),
          decoration: BoxDecoration(
              color: Theme.of(context).highlightColor,
              border: Border(
                  bottom: BorderSide(
                      width: 1, color: Theme.of(context).highlightColor))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              FlatButton(
                  padding: EdgeInsets.zero,
                  child: Text(
                    preferencesTitle,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                        fontSize: 13, decoration: TextDecoration.underline),
                  ),
                  onPressed: () {
                    var model = AppModel.of(context);
                    model.replaceItems(preferences.items);
                    model.replaceSettings(preferences.settings);
                    model.refreshState();
                    Navigator.pop(context);
                  },// id},
                  ),
              IconButton(
                icon: Icon(
                  Icons.delete,
                  size: iconSize,
                  color: Theme.of(context).errorColor,
                ),
                onPressed: () {
                  var model = AppModel.of(context);
                  var db = PreferencesHistoryDb();
                  db.deletePreference(preferences.id);
                  model.refreshState();
                },
              ),
            ],
          ),
        );

  static DrawerSavedSetting preferencesToDrawerSettings(
      AppPreferences preferences, BuildContext context) {
    return DrawerSavedSetting(preferences.title, preferences, context);
  }
}
