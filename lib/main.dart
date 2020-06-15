import 'dart:math';

import 'package:flutter/material.dart';
import 'package:how_many_mobile_meeple/app_builder.dart';
import 'package:how_many_mobile_meeple/platform/list_games_display_route.dart';
import 'package:how_many_mobile_meeple/platform/pages.dart';
import 'package:how_many_mobile_meeple/platform/random_game_display_route.dart';

import 'package:scoped_model/scoped_model.dart';

import 'package:how_many_mobile_meeple/model/model.dart';

import 'homepage.dart';
import 'meeple_theme.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  final routes = <String, WidgetBuilder>{
    HomePage.route: (BuildContext context) => AppBuilder(),
    RandomGameDisplayRoute.route: (BuildContext context) =>
        Pages.platformPages().randomGamePage(),
    ListGamesDisplayRoute.route: (BuildContext context) =>
        Pages.platformPages().listGamesPage(),
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
          home: Pages.platformPages().homePage(),
          routes: routes,
        ));
  }
}
