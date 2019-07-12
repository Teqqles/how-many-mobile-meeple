import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:scoped_multi_example/randomgamedisplay.dart';

import 'model.dart';

class HomePage extends StatefulWidget {
  static final String route = "Home-Page";

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<HomePage> {
  TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Geeklist & User Entry'),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {},
          icon: Icon(Icons.navigate_next),
          label: Text("Random Game"),
        ),
        body: Center(
            child: Column(children: <Widget>[
          Row(
            children: <Widget>[
              SizedBox(width: 20),
              Container(
                width: MediaQuery.of(context).size.width * 0.65,
                child: TextFormField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: "bgg username/geeklist id",
                  ),
                ),
              ),
              SizedBox(width: 20),
              ScopedModelDescendant<AppModel>(
                builder: (context, child, model) => RaisedButton(
                  child: Text('Add'),
                  onPressed: () {
                    if (controller.text.length == 0) return;
                    Item item = Item(controller.text);
                    model.addItem(item);
                    setState(() => controller.text = '');
                  },
                ),
              ),
            ],
          ),
          ScopedModelDescendant<AppModel>(
            builder: (context, child, model) => Slider(
              activeColor: Colors.indigoAccent,
              min: 0.0,
              max: 15.0,
              onChanged: (newRating) {
                setState(() => model.settings.playerCount = newRating.floor());
              },
              value: model.settings.playerCount.roundToDouble(),
            ),
          ),
          ScopedModelDescendant<AppModel>(
            builder: (context, child, model) => Column(
              children: ListTile.divideTiles(
                context: context,
                tiles: model.items.map(
                  (item) => ListTile(
                    title: Text(limitTitleLength(item.name)),
                    trailing: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Icon(Icons.person,
                            size: 30.0,
                            color: colorItem(item, ItemType.collection)),
                        SizedBox(width: 20),
                        Icon(Icons.format_list_bulleted,
                            size: 30.0,
                            color: colorItem(item, ItemType.geekList)),
                        SizedBox(width: 20),
                        Icon(Icons.delete, size: 30.0, color: Colors.red),
                      ],
                      mainAxisSize: MainAxisSize.min,
                    ),
                  ),
                ),
              ).toList(),
            ),
          ),
        ])));
  }

  String limitTitleLength(String text) {
    if (text.length >= 20) {
      text = text.substring(0, 17) + "...";
    }
    return text;
  }

  Color colorItem(Item item, ItemType expectedType) {
    return expectedType == item.itemType ? Colors.blue : Colors.blueGrey;
  }
}
