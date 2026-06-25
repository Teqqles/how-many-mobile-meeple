import 'package:flutter/material.dart';
import 'package:how_many_mobile_meeple/app_common.dart';
import 'package:how_many_mobile_meeple/components/app_choice_chip.dart';
import 'package:how_many_mobile_meeple/components/toggleable_homepage_menu_item_widget.dart';
import 'package:how_many_mobile_meeple/model/mechanics.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';
import 'package:provider/provider.dart';

/// Reusable mechanic filter widget
/// Extracted from HomePage.buildMechanicFilterDisplay()
class MechanicFilterWidget extends StatelessWidget {
  const MechanicFilterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppModel>(
      builder: (context, model, child) {
        var mechanics =
            model.settings.setting(Settings.filterUseAllMechanics.name).value
                ? Mechanics.bggMechanics
                : Mechanics.popularMechanics;
        return Column(
          children: <Widget>[
            ToggleableHomepageMenuItemWidget(
              label: AppCommon.labelMechanics,
              setting: Settings.filterMechanics,
              menuWidget: Wrap(
                alignment: WrapAlignment.center,
                spacing: 5,
                runSpacing: 5,
                children: mechanics.map((String value) {
                  final isSelected = model.settings
                      .setting(Settings.filterMechanics.name)
                      .value
                      .contains(value);
                  final isEnabled = model.settings
                      .setting(Settings.filterMechanics.name)
                      .enabled;
                  return AppMechanicChip(
                    label: value,
                    selected: isSelected,
                    enabled: isEnabled,
                    onSelected: (bool selected) {
                      selected
                          ? model.settings
                              .setting(Settings.filterMechanics.name)
                              .value
                              .add(value)
                          : model.settings
                              .setting(Settings.filterMechanics.name)
                              .value
                              .remove(value);
                      model.invalidateCache();
                      model.updateStore();
                    },
                  );
                }).toList(),
              ),
            )
          ],
        );
      },
    );
  }
}
