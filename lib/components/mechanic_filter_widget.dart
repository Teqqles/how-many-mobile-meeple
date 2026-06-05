import 'package:flutter/material.dart';
import 'package:how_many_mobile_meeple/app_common.dart';
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
                  return ChoiceChip(
                    labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected && isEnabled
                            ? Colors.white
                            : (isEnabled
                                ? Colors.black87
                                : Theme.of(context).disabledColor)),
                    backgroundColor:
                        isEnabled ? Colors.grey[200] : Colors.grey[100],
                    selectedColor: Theme.of(context).colorScheme.secondary,
                    disabledColor: Colors.grey[100],
                    elevation: isEnabled ? 2 : 0,
                    side: BorderSide(
                        color: isEnabled
                            ? (isSelected
                                ? Theme.of(context).colorScheme.secondary
                                : Colors.grey[400]!)
                            : Colors.grey[300]!,
                        width: 1.5),
                    label: Text(value),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      if (!isEnabled) return;
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
