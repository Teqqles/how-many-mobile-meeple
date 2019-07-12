import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:scoped_model/scoped_model.dart';

import 'game_config.dart';
import 'homepage.dart';
import 'how_many_meeple_app_bar.dart';
import 'model.dart';

class RandomGameDisplayPage extends StatelessWidget {
  static final String route = "Display-page";

  static const String findingGames = "Finding games to play";
  static const String speedDisclaimer =
      "this may take some time as board game geek is slow";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: HowManyMeepleAppBar(GameConfig.randomGamePageTitle),
        body: Container(
          child: ScopedModelDescendant<AppModel>(
              builder: (context, child, model) =>
                  loadingSpinnerDisplay(context)),
        ));
  }

  Row loadingSpinnerDisplay(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SpinKitCubeGrid(
                color: Theme.of(context).accentColor,
                size: spinnerScreenWidth(context)),
          ),
          Text(findingGames, style: TextStyle(fontWeight: FontWeight.bold)),
          Text(
            speedDisclaimer,
            style: TextStyle(fontSize: 12),
          )
        ])
      ],
    );
  }

  double spinnerScreenWidth(BuildContext context) {
    double halfScreenWidth = 0.5;
    double screenWidth = MediaQuery.of(context).size.width;
    return screenWidth * halfScreenWidth;
  }
}
