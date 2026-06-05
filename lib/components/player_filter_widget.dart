import 'package:flutter/material.dart';
import 'package:how_many_mobile_meeple/app_common.dart';
import 'package:how_many_mobile_meeple/components/filter_value_badge.dart';
import 'package:how_many_mobile_meeple/components/toggleable_homepage_menu_item_widget.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';
import 'package:provider/provider.dart';

/// Reusable player count filter widget
/// Extracted from HomePage.buildPlayerSliderDisplay()
class PlayerFilterWidget extends StatelessWidget {
  const PlayerFilterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppModel>(
      builder: (context, model, child) => Column(
        children: <Widget>[
          ToggleableHomepageMenuItemWidget(
            label: AppCommon.labelPlayers,
            setting: Settings.filterNumberOfPlayers,
            menuWidget: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Container(
                  height: 35,
                  width: MediaQuery.of(context).size.width * 0.60,
                  child: Slider(
                      activeColor: Theme.of(context).colorScheme.secondary,
                      min: 1.0,
                      max: 10.0,
                      divisions: 10,
                      onChanged: !model.settings
                              .setting(Settings.filterNumberOfPlayers.name)
                              .enabled
                          ? null
                          : (players) {
                              model.settings
                                  .setting(Settings.filterNumberOfPlayers.name)
                                  .value = players.floor();
                              model.updateStore();
                              model.invalidateCache();
                            },
                      value: model.settings
                          .setting(Settings.filterNumberOfPlayers.name)
                          .getInt()
                          .toDouble(),
                      label:
                          "${model.settings.setting(Settings.filterNumberOfPlayers.name).value.toString()} players"),
                ),
                FilterValueBadge(
                  value: model.settings
                      .setting(Settings.filterNumberOfPlayers.name)
                      .value
                      .toString(),
                  isEnabled: model.settings
                      .setting(Settings.filterNumberOfPlayers.name)
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
