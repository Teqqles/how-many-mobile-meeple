import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:how_many_mobile_meeple/model/app_preferences.dart';

class DrawerSavedSetting extends Container {
  final String filterTitle;
  final String id;

  DrawerSavedSetting(this.filterTitle, this.id, BuildContext context)
      : super(
          padding: EdgeInsets.only(top: 12, bottom: 12, left: 8, right: 8),
          decoration: BoxDecoration(
              color: Theme.of(context).highlightColor,
              border: Border(
                  bottom: BorderSide(
                      width: 1, color: Theme.of(context).highlightColor))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              FlatButton(
                  child: Text(
                    filterTitle,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                        fontSize: 13, decoration: TextDecoration.underline),
                  ),
                  onPressed: () {} // id},
                  )
            ],
          ),
        );

  static DrawerSavedSetting preferencesToDrawSettings(
      AppPreferences preferences, BuildContext context) {
    return DrawerSavedSetting(preferences.id, preferences.title, context);
  }

  @override
  bool operator ==(other) {

  }

  @override
  int get hashCode => filterTitle.hashCode + id.hashCode;
}
