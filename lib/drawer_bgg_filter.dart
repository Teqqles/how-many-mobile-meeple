import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'app_default_padding.dart';
import 'model/model.dart';
import 'model/setting.dart';

class DrawerBggFilter extends Container {
  DrawerBggFilter(
      String filterTitle, Setting setting, AppModel model, BuildContext context)
      : super(
          color: Theme.of(context).highlightColor,
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
              Switch(
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
