import 'dart:math';

import 'package:flutter/material.dart';
import 'package:how_many_mobile_meeple/app_builder.dart';

import 'package:scoped_model/scoped_model.dart';

import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/random_game_display.dart';

import 'homepage.dart';
import 'list_games_display.dart';
import 'meeple_theme.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  final routes = <String, WidgetBuilder>{
    HomePage.route: (BuildContext context) => AppBuilder(),
    RandomGameDisplayPage.route: (BuildContext context) =>
        RandomGameDisplayPage(),
    ListGamesDisplayPage.route: (BuildContext context) =>
        ListGamesDisplayPage(),
  };

  final List<Color> swatchList = [
    MeepleTheme.meepleBlue,
    MeepleTheme.meepleGreen,
    MeepleTheme.meepleRed
  ];

  Color randomThemeColor() {
    int swatchIndex = Random().nextInt(swatchList.length);
    return swatchList[swatchIndex];
  }

  @override
  Widget build(BuildContext context) {
    var swatch = randomThemeColor();
    return ScopedModel<AppModel>(
        model: AppModel(),
        child: MaterialApp(
          title: 'How Many Meeple?',
          theme: ThemeData(
            primarySwatch: swatch,
          ),
          home: AppBuilder(),
          routes: routes,
        ));
  }
}
