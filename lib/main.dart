import 'package:flutter/material.dart';

import 'package:scoped_model/scoped_model.dart';

import 'package:scoped_multi_example/model.dart';
import 'package:scoped_multi_example/randomgamedisplay.dart';

import 'homepage.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  final routes = <String, WidgetBuilder>{
    HomePage.route: (BuildContext context) => HomePage(),
    RandomGameDisplayPage.route: (BuildContext context) => RandomGameDisplayPage(),
  };

  @override
  Widget build(BuildContext context) {
    return ScopedModel<AppModel>(
        model: AppModel(),
        child: MaterialApp(
          title: 'How Many Meeple?',
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          home: HomePage(),
          routes: routes,
        )

        );
  }
}

