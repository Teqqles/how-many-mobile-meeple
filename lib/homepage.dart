import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_splash_screen/flutter_splash_screen.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:how_many_mobile_meeple/settings.dart';

import 'app_default_padding.dart';
import 'app_page.dart';
import 'disclaimer_text.dart';
import 'game_config.dart';
import 'how_many_meeple_app_bar.dart';
import 'model.dart';

class HomePage extends StatefulWidget {
  static final String route = "Home-page";

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<HomePage> with GameConfig, AppPage {
  TextEditingController controller = TextEditingController();

  static const String itemHintTextMessage = "bgg username/geeklist id";
  static const String maxItemsMessage = "max items entered";

  @override
  void initState() {
    super.initState();
    hideScreen();
  }

  Future<void> hideScreen() async {
    Future.delayed(Duration(milliseconds: GameConfig.splashScreenDisplayTime),
        () => FlutterSplashScreen.hide());
  }

  @override
  Widget build(BuildContext context) {
    var textFieldWidth = MediaQuery.of(context).size.width * 0.65;
    return Scaffold(
        appBar: HowManyMeepleAppBar(GameConfig.optionsPageTitle),
        floatingActionButton: floatingActionButtonGroup(context),
        body: SingleChildScrollView(
            child: Column(children: <Widget>[
          buildBoardGameItemTextField(textFieldWidth),
          buildPlayerSliderDisplay(),
          buildGameDurationSliderDisplay(),
          buildBoardGameGeekItemDisplay(),
        ])),
        persistentFooterButtons: <Widget>[footerDisplay()]);
  }

  ScopedModelDescendant<AppModel> buildPlayerSliderDisplay() =>
      ScopedModelDescendant<AppModel>(
        builder: (context, child, model) => Column(
          children: <Widget>[
            Container(
              color: Theme.of(context).highlightColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppDefaultPadding(
                    child: Text("Players?", textAlign: TextAlign.left),
                  ),
                  Switch(
                      onChanged: (bool value) {
                        setState(() {
                          model.settings
                              .setting(Settings.filterNumberOfPlayers.name)
                              .enabled = value;
                          model.updateStore();
                        });
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
                              setState(() {
                                model.settings
                                    .setting(
                                        Settings.filterNumberOfPlayers.name)
                                    .value = players.floor();
                                model.updateStore();
                              });
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
              width: textFieldWidth,
              child: ScopedModelDescendant<AppModel>(
                builder: (context, child, model) => TextFormField(
                  enabled: model.items.length < GameConfig.maxItemsFromBgg,
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: model.items.length < GameConfig.maxItemsFromBgg
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
                    setState(() {
                      controller.text = '';
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ));

  ScopedModelDescendant<AppModel> buildGameDurationSliderDisplay() {
    var sliderWidth = MediaQuery.of(context).size.width * 0.60;
    var sliderMinValue = 15.0;
    var sliderMaxValue = 300.0;
    var sliderSteps = 19;
    return ScopedModelDescendant<AppModel>(
      builder: (context, child, model) => Column(
        children: <Widget>[
          Container(
            color: Theme.of(context).highlightColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                AppDefaultPadding(
                  child: Text("Time?", textAlign: TextAlign.left),
                ),
                Switch(
                    onChanged: (bool value) {
                      setState(() {
                        model.settings
                            .setting(Settings.filterMinimumTimeToPlay.name)
                            .enabled = true;
                        model.updateStore();
                      });
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
                          setState(() {
                            model.settings
                                .setting(Settings.filterMinimumTimeToPlay.name)
                                .value = time.start.floor();
                            model.settings
                                .setting(Settings.filterMaximumTimeToPlay.name)
                                .value = time.end.floor();
                            model.updateStore();
                          });
                        },
                  values: RangeValues(
                      model.settings
                          .setting(Settings.filterMinimumTimeToPlay.name)
                          .value
                          .floorToDouble(),
                      model.settings
                          .setting(Settings.filterMinimumTimeToPlay.name)
                          .value
                          .floorToDouble()),
                  labels: RangeLabels(
                      "${model.settings.setting(Settings.filterMinimumTimeToPlay.name).value.toString()} mins",
                      "${model.settings..setting(Settings.filterMaximumTimeToPlay.name).value.toString()} mins"),
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

  ScopedModelDescendant<AppModel> buildBoardGameGeekItemDisplay() {
    var iconSize = 30.0;
    return ScopedModelDescendant<AppModel>(
      builder: (context, child, model) => Column(
        children: <Widget>[
          Container(
              color: Theme.of(context).highlightColor,
              child: AppDefaultPadding(
                child: Row(children: [Text("Usernames/Geeklists Selected")]),
              )),
          Column(
            children: ListTile.divideTiles(
              context: context,
              tiles: model.items.map(
                (item) => ListTile(
                  title: Text(limitTitleLength(item.name)),
                  trailing: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      IconButton(
                          icon: Icon(Icons.person,
                              size: iconSize,
                              color: colorItem(item, ItemType.collection)),
                          onPressed: () {
                            setState(() {
                              item.itemType = ItemType.collection;
                            });
                          }),
                      IconButton(
                          icon: Icon(Icons.format_list_bulleted,
                              size: iconSize,
                              color: colorItem(item, ItemType.geekList)),
                          onPressed: () {
                            setState(() {
                              item.itemType = ItemType.geekList;
                            });
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
              ),
            ).toList(),
          ),
        ],
      ),
    );
  }

  Widget footerDisplay() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[DisclaimerText(GameConfig.disclaimerText, context)],
      );

  String limitTitleLength(String text) {
    if (text.length > 20) {
      text = "${text.substring(0, 18)}...";
    }
    return text;
  }

  Color colorItem(Item item, ItemType expectedType) =>
      expectedType == item.itemType
          ? Theme.of(context).accentColor
          : Theme.of(context).disabledColor;
}
