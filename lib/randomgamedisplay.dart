import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:scoped_model/scoped_model.dart';

import 'homepage.dart';
import 'model.dart';

class RandomGameDisplayPage extends StatelessWidget {
  static final String route = "Display-page";

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
        appBar: AppBar(
          title: Text('Users/GeekLists'),
          actions: <Widget>[
            RaisedButton(
              child: Text('Change Options'),
              onPressed: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) => HomePage()));
              },
            )
          ],
        ),
        body: Container(
          child: ScopedModelDescendant<AppModel>(
              builder: (context, child, model) => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: SpinKitCubeGrid(
                                color: Theme.of(context).accentColor,
                                size: screenWidth * 0.5
                              ),
                            ),
                            Text("Finding games to play",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              "this may take some time as board game geek is slow",
                              style: TextStyle(fontSize: 12),
                            )
                          ])
                    ],
                  )
//                Column(
//                children: model.items
//                    .map((item) => ListTile(
//                  title: Text(item.name),
//                  onLongPress: () {
//                    model.deleteItem(item);
//                  },
//                ))
//                    .toList()),
              ),
        ));
  }
}
