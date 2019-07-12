

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';

import 'homepage.dart';
import 'model.dart';

class RandomGameDisplayPage extends StatelessWidget {
  static final String route = "Display-page";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Users/GeekLists'),
          actions: <Widget>[
            RaisedButton(
              child: Text('Change Options'),
              onPressed: () {
                Navigator
                    .of(context)
                    .push(MaterialPageRoute(builder: (context) => HomePage()));
              },
            )
          ],
        ),
        body: Container(
          child: ScopedModelDescendant<AppModel>(
            builder: (context, child, model) => Column(
                children: model.items
                    .map((item) => ListTile(
                  title: Text(item.name),
                  onLongPress: () {
                    model.deleteItem(item);
                  },
                ))
                    .toList()),
          ),
        ));
  }
}