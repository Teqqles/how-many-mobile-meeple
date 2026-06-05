import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:how_many_mobile_meeple/components/toggleable_homepage_menu_item_widget.dart';
import 'package:how_many_mobile_meeple/platform/web_or_tablet/web_version_info.dart';
import 'package:how_many_mobile_meeple/str_cast.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';

import 'package:how_many_mobile_meeple/components/app_default_padding.dart';
import 'app_page.dart';
import 'package:how_many_mobile_meeple/components/disclaimer_text.dart';
import 'app_common.dart';
import 'components/empty_widget.dart';
import 'how_many_meeple_app_bar.dart';
import 'package:how_many_mobile_meeple/model/item.dart';
import 'package:how_many_mobile_meeple/model/model.dart';

import 'model/mechanics.dart';
import 'theme_extensions.dart';

class HomePage extends StatelessWidget with AppPage {
  static final String route = "Home-page";
  final TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final model = AppModel.of(context, listen: false);
    if (!model.hasLoadedPersistedData) {
      model.loadStoredData();
      model.refreshFromUrl();
    }
    var textFieldWidth = MediaQuery.of(context).size.width * 0.65;
    return Scaffold(
        appBar: HowManyMeepleAppBar(AppCommon.optionsPageTitle,
            hasSaveDialog: true,
            isHomePage: true,
            model: model,
            context: context),
        drawer: pageDrawer(context),
        bottomNavigationBar: Container(
          color: Theme.of(context).highlightColor,
          child: AppDefaultPadding(
            child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  FutureBuilder<Widget>(
                      future: footerDisplay(context),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) return snapshot.data!;
                        return EmptyWidget();
                      })
                ]),
          ),
        ),
        body: SingleChildScrollView(
            child: Column(children: <Widget>[
          buildBoardGameItemTextField(textFieldWidth),
          buildBoardGameGeekItemDisplay(),
          buildGameDurationSliderDisplay(context),
          buildPlayerSliderDisplay(),
          buildComplexitySliderDisplay(),
          buildRatingSliderDisplay(),
          buildMechanicFilterDisplay(context),
        ])),
        persistentFooterButtons: [iconButtonGroup(context)]);
  }

  Consumer<AppModel> buildComplexitySliderDisplay() => Consumer<AppModel>(
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
                        min: 0.0,
                        max: 5.0,
                        divisions: 10,
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
                        value: StrCast(model.settings
                                .setting(Settings.filterComplexity.name)
                                .value)
                            .castToDouble(),
                        label:
                            "${model.settings.setting(Settings.filterComplexity.name).value.toString()} weighting"),
                  ),
                  AppDefaultPadding(
                    child: Container(
                      decoration: ShapeDecoration(
                          color: model.settings
                                  .setting(Settings.filterComplexity.name)
                                  .enabled
                              ? Theme.of(context).colorScheme.secondary
                              : Theme.of(context).disabledColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          )),
                      child: AppDefaultPadding(
                        child: Text(
                            model.settings
                                .setting(Settings.filterComplexity.name)
                                .value
                                .toString(),
                            textAlign: TextAlign.right,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).selectedRowColor)),
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      );

  Consumer<AppModel> buildPlayerSliderDisplay() => Consumer<AppModel>(
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
                                    .setting(
                                        Settings.filterNumberOfPlayers.name)
                                    .value = players.floor();
                                model.updateStore();
                                model.invalidateCache();
                              },
                        value: StrCast(model.settings
                                .setting(Settings.filterNumberOfPlayers.name)
                                .value)
                            .castToInt()
                            .roundToDouble(),
                        label:
                            "${model.settings.setting(Settings.filterNumberOfPlayers.name).value.toString()} players"),
                  ),
                  AppDefaultPadding(
                    child: Container(
                      decoration: ShapeDecoration(
                          color: model.settings
                                  .setting(Settings.filterNumberOfPlayers.name)
                                  .enabled
                              ? Theme.of(context).colorScheme.secondary
                              : Theme.of(context).disabledColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          )),
                      child: AppDefaultPadding(
                        child: Text(
                            model.settings
                                .setting(Settings.filterNumberOfPlayers.name)
                                .value
                                .toString(),
                            textAlign: TextAlign.right,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).selectedRowColor)),
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      );

  Consumer<AppModel> buildRatingSliderDisplay() => Consumer<AppModel>(
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
                        value: StrCast(model.settings
                                .setting(Settings.filterMinRating.name)
                                .value)
                            .castToDouble(),
                        label:
                            "${model.settings.setting(Settings.filterMinRating.name).value.toString()} rating"),
                  ),
                  AppDefaultPadding(
                    child: Container(
                      decoration: ShapeDecoration(
                          color: model.settings
                                  .setting(Settings.filterMinRating.name)
                                  .enabled
                              ? Theme.of(context).colorScheme.secondary
                              : Theme.of(context).disabledColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          )),
                      child: AppDefaultPadding(
                        child: Text(
                            model.settings
                                .setting(Settings.filterMinRating.name)
                                .value
                                .toString(),
                            textAlign: TextAlign.right,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).selectedRowColor)),
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      );

  Widget buildBoardGameItemTextField(double textFieldWidth) => Align(
      alignment: Alignment.centerLeft,
      child: AppDefaultPadding(
        child: Row(
          children: <Widget>[
            Container(
              height: 35,
              width: textFieldWidth,
              child: Consumer<AppModel>(
                builder: (context, model, child) => TextFormField(
                  enabled:
                      model.items.itemList.length < AppCommon.maxItemsFromBgg,
                  controller: controller,
                  decoration: InputDecoration(
                    hintText:
                        model.items.itemList.length < AppCommon.maxItemsFromBgg
                            ? AppCommon.itemHintTextMessage
                            : AppCommon.maxItemsMessage,
                  ),
                ),
              ),
            ),
            Consumer<AppModel>(
              builder: (context, model, child) => AppDefaultPadding(
                child: ElevatedButton(
                  child: Text('Add'),
                  onPressed: () {
                    if (controller.text.isEmpty) return;
                    Item item = Item(controller.text.trim());
                    model.addItem(item);
                    controller.text = '';
                    model.updateStore();
                  },
                ),
              ),
            ),
          ],
        ),
      ));

  Consumer<AppModel> buildGameDurationSliderDisplay(BuildContext context) {
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
                  Switch(
                      activeThumbColor: Colors.white,
                      activeTrackColor: Theme.of(context).colorScheme.primary,
                      inactiveThumbColor: Colors.grey[600],
                      inactiveTrackColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.5),
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
                        StrCast(model.settings
                                .setting(Settings.filterMinimumTimeToPlay.name)
                                .value)
                            .castToInt()
                            .floorToDouble(),
                        StrCast(model.settings
                                .setting(Settings.filterMaximumTimeToPlay.name)
                                .value)
                            .castToInt()
                            .floorToDouble()),
                    labels: RangeLabels(
                        "${model.settings.setting(Settings.filterMinimumTimeToPlay.name).value.toString()} mins",
                        "${model.settings.setting(Settings.filterMaximumTimeToPlay.name).value.toString()} mins"),
                  ),
                ),
                AppDefaultPadding(
                  child: Container(
                    decoration: ShapeDecoration(
                        color: model.settings
                                .setting(Settings.filterMinimumTimeToPlay.name)
                                .enabled
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(context).disabledColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        )),
                    child: AppDefaultPadding(
                      child: Text(
                          "${model.settings.setting(Settings.filterMinimumTimeToPlay.name).value.toString()}-${model.settings.setting(Settings.filterMaximumTimeToPlay.name).value.toString()} mins",
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).selectedRowColor)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Consumer<AppModel> buildMechanicFilterDisplay(BuildContext context) {
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

  Consumer<AppModel> buildBoardGameGeekItemDisplay() {
    return Consumer<AppModel>(
      builder: (context, model, child) => Column(
        children: <Widget>[
          Container(
              height: 35,
              color: Theme.of(context).colorScheme.primaryContainer,
              child: AppDefaultPadding(
                child: Row(children: [
                  Text(
                    "Usernames/Geeklists Selected",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  )
                ]),
              )),
          Column(
            children: ListTile.divideTiles(
                    context: context, tiles: itemsSelected(context, model))
                .toList(),
          ),
        ],
      ),
    );
  }

  Iterable<Widget> itemsSelected(BuildContext context, AppModel model) {
    if (model.items.isEmpty) {
      return [
        ListTile(
            title: Text(
          "No Items Selected",
          style:
              TextStyle(fontSize: 13, color: Theme.of(context).disabledColor),
        ))
      ];
    }
    return model.items.itemList.map(
      (item) => ListTile(
        title: Text(limitTitleLength(item.name)),
        trailing: SizedBox(
          width: 144, // Constrain to reasonable width for 3 icon buttons
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  icon: Icon(Icons.person,
                      size: AppCommon.standardIconSize,
                      color: colorItem(context, item, ItemType.collection)),
                  onPressed: () {
                    item.itemType = ItemType.collection;
                    model.invalidateCache();
                    model.updateStore();
                  }),
              IconButton(
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  icon: Icon(Icons.format_list_bulleted,
                      size: AppCommon.standardIconSize,
                      color: colorItem(context, item, ItemType.geekList)),
                  onPressed: () {
                    item.itemType = ItemType.geekList;
                    model.invalidateCache();
                    model.updateStore();
                  }),
              IconButton(
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                icon: Icon(
                  Icons.delete,
                  size: AppCommon.standardIconSize,
                  color: Theme.of(context).colorScheme.error,
                ),
                onPressed: () {
                  model.deleteItem(item);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String> getAppVersion() async {
    if (kIsWeb) {
      return WebVersionInfo.name;
    } else {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    }
  }

  Future<Widget> footerDisplay(BuildContext context) async {
    var version = await getAppVersion();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: BGGAttribution(),
        ),
        DisclaimerText("(v:$version)", context)
      ],
    );
  }

  String limitTitleLength(String text) {
    if (text.length > 20) {
      text = "${text.substring(0, 18)}...";
    }
    return text;
  }

  Color colorItem(BuildContext context, Item item, ItemType expectedType) =>
      expectedType == item.itemType
          ? Theme.of(context).colorScheme.secondary
          : Theme.of(context).disabledColor;
}
