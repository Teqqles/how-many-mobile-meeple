import 'package:flutter/material.dart';
import 'package:how_many_mobile_meeple/app_common.dart';
import 'package:how_many_mobile_meeple/components/filter_value_badge.dart';
import 'package:how_many_mobile_meeple/components/toggleable_homepage_menu_item_widget.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';
import 'package:provider/provider.dart';

/// Reusable rating filter widget
/// Extracted from HomePage.buildRatingSliderDisplay()
class RatingFilterWidget extends StatelessWidget {
  const RatingFilterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppModel>(
      builder: (context, model, child) => Column(
        children: <Widget>[
          ToggleableHomepageMenuItemWidget(
            label: AppCommon.labelRating,
            setting: Settings.filterMinRating,
            menuWidget: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Container(
                  height: 35,
                  width: MediaQuery.of(context).size.width * 0.60,
                  child: Slider(
                      activeColor: Theme.of(context).colorScheme.secondary,
                      min: 0.0,
                      max: 10.0,
                      divisions: 20,
                      onChanged: !model.settings
                              .setting(Settings.filterMinRating.name)
                              .enabled
                          ? null
                          : (rating) {
                              model.settings
                                  .setting(Settings.filterMinRating.name)
                                  .value = rating;
                              model.updateStore();
                              model.invalidateCache();
                            },
                      value: model.settings
                          .setting(Settings.filterMinRating.name)
                          .getDouble(),
                      label:
                          "${model.settings.setting(Settings.filterMinRating.name).value.toString()} rating"),
                ),
                FilterValueBadge(
                  value: model.settings
                      .setting(Settings.filterMinRating.name)
                      .value
                      .toString(),
                  isEnabled:
                      model.settings.setting(Settings.filterMinRating.name).enabled,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
