import 'package:flutter/material.dart';
import 'package:how_many_mobile_meeple/app_common.dart';
import 'package:how_many_mobile_meeple/components/filter_value_badge.dart';
import 'package:how_many_mobile_meeple/components/toggleable_homepage_menu_item_widget.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';
import 'package:provider/provider.dart';

/// Reusable complexity filter widget
/// Extracted from HomePage.buildComplexitySliderDisplay()
class ComplexityFilterWidget extends StatelessWidget {
  const ComplexityFilterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppModel>(
      builder: (context, model, child) => Column(
        children: <Widget>[
          ToggleableHomepageMenuItemWidget(
            label: AppCommon.labelDifficulty,
            setting: Settings.filterComplexity,
            menuWidget: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Container(
                  height: 35,
                  width: MediaQuery.of(context).size.width * 0.60,
                  child: Slider(
                      activeColor: Theme.of(context).colorScheme.secondary,
                      min: 0.5,
                      max: 5.0,
                      divisions: 9,
                      onChanged: !model.settings
                              .setting(Settings.filterComplexity.name)
                              .enabled
                          ? null
                          : (complexity) {
                              model.settings
                                  .setting(Settings.filterComplexity.name)
                                  .value = complexity;
                              model.updateStore();
                              model.invalidateCache();
                            },
                      value: model.settings
                          .setting(Settings.filterComplexity.name)
                          .getDouble()
                          .clamp(0.5, 5.0),
                      label:
                          "~${model.settings.setting(Settings.filterComplexity.name).value.toString()} weighting"),
                ),
                FilterValueBadge(
                  value:
                      "~${model.settings.setting(Settings.filterComplexity.name).value.toString()}",
                  isEnabled: model.settings
                      .setting(Settings.filterComplexity.name)
                      .enabled,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
