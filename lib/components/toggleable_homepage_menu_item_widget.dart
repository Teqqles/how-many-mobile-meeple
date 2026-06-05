import 'package:flutter/material.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/model/setting.dart';
import 'package:provider/provider.dart';

import 'app_default_padding.dart';
import 'app_home_menu_padding.dart';

class ToggleableHomepageMenuItemWidget extends StatelessWidget {
  final String label;
  final Setting setting;
  final Widget menuWidget;

  const ToggleableHomepageMenuItemWidget({
    super.key,
    required this.label,
    required this.setting,
    required this.menuWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppModel>(
      builder: (context, model, child) {
        final isEnabled = model.settings.setting(this.setting.name).enabled;
        return Column(children: <Widget>[
          Container(
            height: 35,
            color: isEnabled
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.primary.withOpacity(0.25),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppDefaultPadding(
                  child: Text(
                    this.label,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontWeight: isEnabled ? FontWeight.bold : FontWeight.normal,
                      color: isEnabled
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Switch(
                    activeColor: Colors.white,
                    activeTrackColor: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    inactiveThumbColor: Colors.grey[600],
                    inactiveTrackColor: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    onChanged: (bool value) {
                      var setting = model.settings.setting(this.setting.name) ??
                          this.setting;
                      setting.enabled = value;
                      model.settings.updateSetting(setting);
                      model.updateStore();
                      model.invalidateCache();
                    },
                    value: isEnabled)
              ],
            ),
          ),
          AppHomeMenuPadding(),
          menuWidget
        ]);
      },
    );
  }
}
