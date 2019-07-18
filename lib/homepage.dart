import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_splash_screen/flutter_splash_screen.dart';
import 'package:scoped_model/scoped_model.dart';

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
      floatingActionButton: floatingRandomGameButton(context),
      body: Column(children: <Widget>[
        buildBoardGameItemTextField(textFieldWidth),
        buildPlayerSliderDisplay(),
        buildGameDurationSliderDisplay(),
        buildBoardGameGeekItemDisplay(),
      ]),
      persistentFooterButtons: <Widget>[footerDisplay()],
    );
  }

  ScopedModelDescendant<AppModel> buildPlayerSliderDisplay() =>
      ScopedModelDescendant<AppModel>(
        builder: (context, child, model) => Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            AppDefaultPadding(
              child: Text("Players?", textAlign: TextAlign.left),
            ),
            Container(
              width: MediaQuery.of(context).size.width * 0.60,
              child: Slider(
                  activeColor: Theme.of(context).accentColor,
                  min: 1.0,
                  max: 10.0,
                  divisions: 10,
                  onChanged: (players) {
                    setState(
                        () => model.settings.playerCount = players.floor());
                  },
                  value: model.settings.playerCount.roundToDouble(),
                  label: "${model.settings.playerCount.toString()} players"),
            ),
            AppDefaultPadding(
              child: Container(
                decoration: ShapeDecoration(
                    color: Theme.of(context).accentColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    )),
                child: AppDefaultPadding(
                  child: Text(model.settings.playerCount.toString(),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).selectedRowColor)),
                ),
              ),
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
                    Item item = Item(controller.text);
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
    var sliderWidth = MediaQuery.of(context).size.width * 0.55;
    var sliderMinValue = 15.0;
    var sliderMaxValue = 300.0;
    var sliderSteps = 19;
    return ScopedModelDescendant<AppModel>(
      builder: (context, child, model) => Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          AppDefaultPadding(
            child: Text("Time?", textAlign: TextAlign.left),
          ),
          Container(
            width: sliderWidth,
            child: RangeSlider(
              activeColor: Theme.of(context).accentColor,
              min: sliderMinValue,
              max: sliderMaxValue,
              divisions: sliderSteps,
              onChanged: (time) {
                setState(() {
                  model.settings.minTime = time.start.floor();
                  model.settings.maxTime = time.end.floor();
                });
              },
              values: RangeValues(model.settings.minTime.floorToDouble(),
                  model.settings.maxTime.floorToDouble()),
              labels: RangeLabels("${model.settings.minTime.toString()} mins",
                  "${model.settings.maxTime.toString()} mins"),
            ),
          ),
          AppDefaultPadding(
            child: Container(
              decoration: ShapeDecoration(
                  color: Theme.of(context).accentColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  )),
              child: AppDefaultPadding(
                child: Text(
                    "${model.settings.minTime.toString()}-${model.settings.maxTime.toString()} mins",
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).selectedRowColor)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  ScopedModelDescendant<AppModel> buildBoardGameGeekItemDisplay() {
    var iconSize = 30.0;
    return ScopedModelDescendant<AppModel>(
      builder: (context, child, model) => Column(
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
    );
  }

  Widget footerDisplay() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    crossAxisAlignment: CrossAxisAlignment.end,
    children: <Widget>[
      DisclaimerText(GameConfig.disclaimerText, context)
    ],
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
