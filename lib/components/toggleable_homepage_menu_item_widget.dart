import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/model/setting.dart';
import 'package:scoped_model/scoped_model.dart';

import 'app_default_padding.dart';
import 'app_home_menu_padding.dart';

class ToggleableHomepageMenuItemWidget extends StatelessWidget {
  final String label;
  final Setting setting;
  final Widget menuWidget;

  ToggleableHomepageMenuItemWidget({this.label, this.setting, this.menuWidget});

  Widget build(context) {
    return ScopedModelDescendant<AppModel>(
      builder: (context, child, model) => Column(children: <Widget>[
        Container(
          height: 35,
          color: Theme.of(context).highlightColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppDefaultPadding(
                child: Text(this.label, textAlign: TextAlign.left),
              ),
              Switch(
                  onChanged: (bool value) {
                    var setting = model.settings.setting(this.setting.name) ??
                        this.setting;
                    setting.enabled = value;
                    model.settings.updateSetting(setting);
                    model.updateStore();
                    model.invalidateCache();
                  },
                  value: model.settings.setting(this.setting.name)?.enabled)
            ],
          ),
        ),
        AppHomeMenuPadding(),
        menuWidget
      ]),
    );
  }
}
