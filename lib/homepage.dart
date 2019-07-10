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
        body: Center(
            child: Column(children: <Widget>[
          Container(
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                hintText: "bgg username/geeklist id",
              ),
            ),
          ),
          Row(
            children: <Widget>[
              ScopedModelDescendant<AppModel>(
                builder: (context, child, model) => RaisedButton(
                  child: Text('Add User or Geeklist'),
                  onPressed: () {
                    Item item = Item(controller.text);
                    model.addItem(item);
                    setState(() => controller.text = '');
                  },
                ),
              ),
//              Spacer(),
//              RaisedButton(
//                child: Text('Edit Users/Geeklists'),
//                onPressed: () {
//                  Navigator.of(context).push(MaterialPageRoute(
//                      builder: (context) => RandomGameDisplayPage()));
//                },
//              )
            ],
          ),
          ScopedModelDescendant<AppModel>(
            builder: (context, child, model) => Column(
              children: ListTile.divideTiles(
                context: context,
                tiles: model.items.map(
                  (item) => ListTile(
                    title: Text(item.name),
                    trailing: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Icon(Icons.delete, size: 30.0, color: Colors.red),
                        Icon(Icons.delete, size: 30.0, color: Colors.red),
                      ],
                    ),
                  ),
                ),
              ).toList(),
            ),
          ),
        ])));
  }
}
