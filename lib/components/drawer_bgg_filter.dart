import 'package:flutter/material.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/model/setting.dart';

import 'package:how_many_mobile_meeple/components/app_default_padding.dart';

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
                  activeThumbColor: Colors.white,
                  activeTrackColor: Theme.of(context).colorScheme.primary,
                  inactiveThumbColor: Colors.grey[600],
                  inactiveTrackColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.5),
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
