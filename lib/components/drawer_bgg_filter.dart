import 'package:flutter/material.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/model/setting.dart';

import 'package:how_many_mobile_meeple/components/app_default_padding.dart';
import 'package:how_many_mobile_meeple/components/drawer_switch.dart';

class DrawerBggFilter extends Container {
  DrawerBggFilter(
      String filterTitle, Setting setting, AppModel model, BuildContext context,
      {int index = 0})
      : super(
          color:
              index % 2 == 0 ? Theme.of(context).highlightColor : Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              AppDefaultPadding(
                child: Text(
                  filterTitle,
                  textAlign: TextAlign.left,
                  style: TextStyle(fontSize: 13),
                ),
              ),
              DrawerSwitch(
                  onChanged: (bool value) {
                    setting.value = value;
                    setting.enabled = true;
                    model.updateStore();
                    model.invalidateCache();
                  },
                  value: setting.value)
            ],
          ),
        );
}
