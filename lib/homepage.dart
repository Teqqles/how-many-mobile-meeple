import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_splash_screen/flutter_splash_screen.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:scoped_multi_example/randomgamedisplay.dart';

import 'model.dart';

class HomePage extends StatefulWidget {
  static final String route = "Home-page";

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<HomePage> {
  TextEditingController controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    hideScreen();
  }

  Future<void> hideScreen() async {
    Future.delayed(Duration(milliseconds: 3600), () {
      FlutterSplashScreen.hide();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: buildHowManyMeepleAppbar('Game Options'),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => RandomGameDisplayPage(),
              ),
            );
          },
          icon: SizedBox(
            height: 42,
            width: 42,
            child: Image.asset('lib/images/dice.png'),
          ),
          label: Text("Random Game"),
        ),
        body: Column(children: <Widget>[
          Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: MediaQuery.of(context).size.width * 0.65,
                      child: ScopedModelDescendant<AppModel>(
                        builder: (context, child, model) => TextFormField(
                          enabled: model.items.length < 5,
                          controller: controller,
                          decoration: InputDecoration(
                            hintText:
                            model.items.length < 5 ? "bgg username/geeklist id" : "max items entered",
                          ),
                        ),
                      ),
                    ),
                    ScopedModelDescendant<AppModel>(
                      builder: (context, child, model) => Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: RaisedButton(
                          child: Text('Add'),
                          onPressed: () {
                            if (controller.text.length == 0) return;
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
              )),
          ScopedModelDescendant<AppModel>(
            builder: (context, child, model) => Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
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
                      label:
                          model.settings.playerCount.toString() + " players"),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: ShapeDecoration(
                        color: Theme.of(context).accentColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        )),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
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
          ),
          ScopedModelDescendant<AppModel>(
            builder: (context, child, model) => Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text("Time?", textAlign: TextAlign.left),
                ),
                Container(
                  width: MediaQuery.of(context).size.width * 0.55,
                  child: RangeSlider(
                    activeColor: Theme.of(context).accentColor,
                    min: 15.0,
                    max: 300.0,
                    divisions: 19,
                    onChanged: (time) {
                      setState(() {
                        model.settings.minTime = time.start.floor();
                        model.settings.maxTime = time.end.floor();
                      });
                    },
                    values: RangeValues(model.settings.minTime.floorToDouble(),
                        model.settings.maxTime.floorToDouble()),
                    labels: RangeLabels(
                        model.settings.minTime.toString() + " mins",
                        model.settings.maxTime.toString() + " mins"),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: ShapeDecoration(
                        color: Theme.of(context).accentColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        )),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                          model.settings.minTime.toString() +
                              " - " +
                              model.settings.maxTime.toString() +
                              " mins",
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).selectedRowColor)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          buildBoardGameGeekItemDisplay(),
        ]));
  }

  AppBar buildHowManyMeepleAppbar(String subtitle) {
    return AppBar(
      title: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('How Many Meeple?'),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  ScopedModelDescendant<AppModel> buildBoardGameGeekItemDisplay() {
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
                          size: 30.0,
                          color: colorItem(item, ItemType.collection)),
                      onPressed: () {
                        setState(() {
                          item.itemType = ItemType.collection;
                        });
                      }),
                  IconButton(
                      icon: Icon(Icons.format_list_bulleted,
                          size: 30.0,
                          color: colorItem(item, ItemType.geekList)),
                      onPressed: () {
                        setState(() {
                          item.itemType = ItemType.geekList;
                        });
                      }),
                  IconButton(
                    icon: Icon(
                      Icons.delete,
                      size: 30.0,
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

  String limitTitleLength(String text) {
    if (text.length >= 20) {
      text = text.substring(0, 17) + "...";
    }
    return text;
  }

  Color colorItem(Item item, ItemType expectedType) {
    return expectedType == item.itemType
        ? Theme.of(context).accentColor
        : Theme.of(context).disabledColor;
  }
}
