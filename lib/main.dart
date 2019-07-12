import 'dart:math';

import 'package:flutter/material.dart';

import 'package:scoped_model/scoped_model.dart';

import 'package:scoped_multi_example/model.dart';
import 'package:scoped_multi_example/randomgamedisplay.dart';

import 'homepage.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  final routes = <String, WidgetBuilder>{
    HomePage.route: (BuildContext context) => HomePage(),
    RandomGameDisplayPage.route: (BuildContext context) =>
        RandomGameDisplayPage(),
  };

  List<Color> swatchList = [Colors.green, Colors.red, Colors.blue];

  Color randomPrimaryColor() {
    int swatchIndex = Random().nextInt(swatchList.length);
    return swatchList[swatchIndex];
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModel<AppModel>(
        model: AppModel(),
        child: MaterialApp(
          title: 'How Many Meeple?',
          theme: ThemeData(
            primarySwatch: randomPrimaryColor(),
          ),
          home: HomePage(),
          routes: routes,
        ));
  }
}
