import 'package:flutter/material.dart';
import 'package:how_many_mobile_meeple/app_common.dart';
import 'package:how_many_mobile_meeple/components/app_default_padding.dart';
import 'package:how_many_mobile_meeple/components/app_switch.dart';
import 'package:how_many_mobile_meeple/components/filter_value_badge.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';
import 'package:provider/provider.dart';

/// Reusable time/duration filter widget
/// Extracted from HomePage.buildGameDurationSliderDisplay()
class TimeFilterWidget extends StatelessWidget {
  const TimeFilterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    var sliderWidth = MediaQuery.of(context).size.width * 0.60;
    var sliderMinValue = 15.0;
    var sliderMaxValue = 300.0;
    var sliderSteps = 19;

    return Consumer<AppModel>(
      builder: (context, model, child) {
        final isEnabled = model.settings
            .setting(Settings.filterMinimumTimeToPlay.name)
            .enabled;
        return Column(
          children: <Widget>[
            Container(
              height: 35,
              color: isEnabled
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.25),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  AppDefaultPadding(
                    child: Text(
                      AppCommon.labelTime,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontWeight:
                            isEnabled ? FontWeight.bold : FontWeight.normal,
                        color: isEnabled
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  AppSwitch(
                      style: AppSwitchStyle.subtle,
                      onChanged: (bool value) {
                        model.settings
                            .setting(Settings.filterMinimumTimeToPlay.name)
                            .enabled = value;
                        model.settings
                            .setting(Settings.filterMaximumTimeToPlay.name)
                            .enabled = value;
                        model.updateStore();
                        model.invalidateCache();
                      },
                      value: isEnabled)
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: sliderWidth,
                  child: RangeSlider(
                    activeColor: Theme.of(context).colorScheme.secondary,
                    min: sliderMinValue,
                    max: sliderMaxValue,
                    divisions: sliderSteps,
                    onChanged: !model.settings
                            .setting(Settings.filterMinimumTimeToPlay.name)
                            .enabled
                        ? null
                        : (time) {
                            model.settings
                                .setting(Settings.filterMinimumTimeToPlay.name)
                                .value = time.start.floor();
                            model.settings
                                .setting(Settings.filterMaximumTimeToPlay.name)
                                .value = time.end.floor();
                            model.updateStore();
                            model.invalidateCache();
                          },
                    values: RangeValues(
                        model.settings
                            .setting(Settings.filterMinimumTimeToPlay.name)
                            .getInt()
                            .toDouble(),
                        model.settings
                            .setting(Settings.filterMaximumTimeToPlay.name)
                            .getInt()
                            .toDouble()),
                    labels: RangeLabels(
                        "${model.settings.setting(Settings.filterMinimumTimeToPlay.name).value.toString()} mins",
                        "${model.settings.setting(Settings.filterMaximumTimeToPlay.name).value.toString()} mins"),
                  ),
                ),
                FilterValueBadge(
                  value:
                      "${model.settings.setting(Settings.filterMinimumTimeToPlay.name).value.toString()}-${model.settings.setting(Settings.filterMaximumTimeToPlay.name).value.toString()} mins",
                  isEnabled: model.settings
                      .setting(Settings.filterMinimumTimeToPlay.name)
                      .enabled,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
