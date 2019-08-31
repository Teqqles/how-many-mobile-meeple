import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';

import 'app_default_padding.dart';
import 'app_page.dart';
import 'disclaimer_text.dart';
import 'app_common.dart';
import 'how_many_meeple_app_bar.dart';
import 'package:how_many_mobile_meeple/model/item.dart';
import 'package:how_many_mobile_meeple/model/model.dart';

import 'model/mechanics.dart';

class HomePage extends StatelessWidget with AppCommon, AppPage {
  static final String route = "Home-page";
  final TextEditingController controller = TextEditingController();

  static const String itemHintTextMessage = "bgg username/geeklist id";
  static const String maxItemsMessage = "max items entered";

  @override
  Widget build(BuildContext context) {
    if (!AppModel.of(context).hasLoadedPersistedData) {
      AppModel.of(context).loadStoredData();
    }
    var textFieldWidth = MediaQuery.of(context).size.width * 0.65;
    return Scaffold(
        appBar: HowManyMeepleAppBar(AppCommon.optionsPageTitle,
            hasSaveDialog: true, model: AppModel.of(context), context: context),
        drawer: pageDrawer(context),
        bottomNavigationBar: Container(
          color: Theme.of(context).highlightColor,
          child: AppDefaultPadding(
            child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  FutureBuilder(
                      future: footerDisplay(context),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) return snapshot.data;
                        return Text("");
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
          buildMechanicFilterDisplay(context),
        ])),
        persistentFooterButtons: [iconButtonGroup(context)]);
  }

  ScopedModelDescendant<AppModel> buildComplexitySliderDisplay() =>
      ScopedModelDescendant<AppModel>(
        builder: (context, child, model) => Column(
          children: <Widget>[
            Container(
              height: 35,
              color: Theme.of(context).highlightColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppDefaultPadding(
                    child: Text("How Difficult?", textAlign: TextAlign.left),
                  ),
                  Switch(
                      onChanged: (bool value) {
                        model.settings
                            .setting(Settings.filterComplexity.name)
                            .enabled = value;
                        model.updateStore();
                        model.invalidateCache();
                      },
                      value: model.settings
                          .setting(Settings.filterComplexity.name)
                          .enabled)
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Container(
                  height: 35,
                  width: MediaQuery.of(context).size.width * 0.60,
                  child: Slider(
                      activeColor: Theme.of(context).accentColor,
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
                      value: model.settings
                          .setting(Settings.filterComplexity.name)
                          .value,
                      label:
                          "${model.settings.setting(Settings.filterComplexity.name).value.toString()} weighting"),
                ),
                AppDefaultPadding(
                  child: Container(
                    decoration: ShapeDecoration(
                        color: model.settings
                                .setting(Settings.filterComplexity.name)
                                .enabled
                            ? Theme.of(context).accentColor
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
          ],
        ),
      );

  ScopedModelDescendant<AppModel> buildPlayerSliderDisplay() =>
      ScopedModelDescendant<AppModel>(
        builder: (context, child, model) => Column(
          children: <Widget>[
            Container(
              height: 35,
              color: Theme.of(context).highlightColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppDefaultPadding(
                    child: Text("Players?", textAlign: TextAlign.left),
                  ),
                  Switch(
                      onChanged: (bool value) {
                        model.settings
                            .setting(Settings.filterNumberOfPlayers.name)
                            .enabled = value;
                        model.updateStore();
                        model.invalidateCache();
                      },
                      value: model.settings
                          .setting(Settings.filterNumberOfPlayers.name)
                          .enabled)
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Container(
                  height: 35,
                  width: MediaQuery.of(context).size.width * 0.60,
                  child: Slider(
                      activeColor: Theme.of(context).accentColor,
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
                          .value
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
                            ? Theme.of(context).accentColor
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
              child: ScopedModelDescendant<AppModel>(
                builder: (context, child, model) => TextFormField(
                  enabled:
                      model.items.itemList.length < AppCommon.maxItemsFromBgg,
                  controller: controller,
                  decoration: InputDecoration(
                    hintText:
                        model.items.itemList.length < AppCommon.maxItemsFromBgg
                            ? itemHintTextMessage
                            : maxItemsMessage,
                  ),
                ),
              ),
            ),
            ScopedModelDescendant<AppModel>(
              builder: (context, child, model) => AppDefaultPadding(
                child: RaisedButton(
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

  ScopedModelDescendant<AppModel> buildGameDurationSliderDisplay(
      BuildContext context) {
    var sliderWidth = MediaQuery.of(context).size.width * 0.60;
    var sliderMinValue = 15.0;
    var sliderMaxValue = 300.0;
    var sliderSteps = 19;
    return ScopedModelDescendant<AppModel>(
      builder: (context, child, model) => Column(
        children: <Widget>[
          Container(
            height: 35,
            color: Theme.of(context).highlightColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                AppDefaultPadding(
                  child: Text("Time?", textAlign: TextAlign.left),
                ),
                Switch(
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
                    value: model.settings
                        .setting(Settings.filterMinimumTimeToPlay.name)
                        .enabled)
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Container(
                width: sliderWidth,
                child: RangeSlider(
                  activeColor: Theme.of(context).accentColor,
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
                          .value
                          .floorToDouble(),
                      model.settings
                          .setting(Settings.filterMaximumTimeToPlay.name)
                          .value
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
                          ? Theme.of(context).accentColor
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
      ),
    );
  }

  ScopedModelDescendant<AppModel> buildMechanicFilterDisplay(
      BuildContext context) {
    return ScopedModelDescendant<AppModel>(
      builder: (context, child, model) {
        var mechanics =
            model.settings.setting(Settings.filterUseAllMechanics.name).value
                ? Mechanics.bggMechanics
                : Mechanics.popularMechanics;
        return Column(
          children: <Widget>[
            Container(
              height: 35,
              color: Theme.of(context).highlightColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  AppDefaultPadding(
                    child: Text("Mechanics?", textAlign: TextAlign.left),
                  ),
                  Switch(
                      onChanged: (bool value) {
                        model.settings
                            .setting(Settings.filterMechanics.name)
                            .enabled = value;
                        model.updateStore();
                        model.invalidateCache();
                      },
                      value: model.settings
                          .setting(Settings.filterMechanics.name)
                          .enabled)
                ],
              ),
            ),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 5,
              children: mechanics.map((String value) {
                return ChoiceChip(
                  labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: model.settings
                              .setting(Settings.filterMechanics.name)
                              .enabled
                          ? Theme.of(context).accentColor
                          : Theme.of(context).disabledColor),
                  label: Text(value),
                  selected: model.settings
                      .setting(Settings.filterMechanics.name)
                      .value
                      .contains(value),
                  onSelected: (bool selected) {
                    if (!model.settings
                        .setting(Settings.filterMechanics.name)
                        .enabled) return;
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
            )
          ],
        );
      },
    );
  }

  ScopedModelDescendant<AppModel> buildBoardGameGeekItemDisplay() {
    return ScopedModelDescendant<AppModel>(
      builder: (context, child, model) => Column(
        children: <Widget>[
          Container(
              height: 35,
              color: Theme.of(context).highlightColor,
              child: AppDefaultPadding(
                child: Row(children: [Text("Usernames/Geeklists Selected")]),
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
    var iconSize = 30.0;
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
        trailing: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
                icon: Icon(Icons.person,
                    size: iconSize,
                    color: colorItem(context, item, ItemType.collection)),
                onPressed: () {
                  item.itemType = ItemType.collection;
                  model.invalidateCache();
                  model.updateStore();
                }),
            IconButton(
                icon: Icon(Icons.format_list_bulleted,
                    size: iconSize,
                    color: colorItem(context, item, ItemType.geekList)),
                onPressed: () {
                  item.itemType = ItemType.geekList;
                  model.invalidateCache();
                  model.updateStore();
                }),
            IconButton(
              icon: Icon(
                Icons.delete,
                size: iconSize,
                color: Theme.of(context).errorColor,
              ),
              onPressed: () {
                model.deleteItem(item);
              },
            ),
          ],
          mainAxisSize: MainAxisSize.min,
        ),
      ),
    );
  }

  Future<Widget> footerDisplay(BuildContext context) async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: DisclaimerText(AppCommon.disclaimerText, context),
        ),
        DisclaimerText("(v:${packageInfo.version})", context)
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
          ? Theme.of(context).accentColor
          : Theme.of(context).disabledColor;
}
