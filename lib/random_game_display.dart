import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:scoped_multi_example/screen_tools.dart';

import 'app_default_padding.dart';
import 'app_page.dart';
import 'game_config.dart';
import 'how_many_meeple_app_bar.dart';
import 'load_games.dart';
import 'network_content_widget.dart';

class RandomGameDisplayPage extends NetworkWidget with AppPage {
  static final String route = "Random-game-page";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: HowManyMeepleAppBar(GameConfig.randomGamePageTitle),
        floatingActionButton: floatingActionButtonGroup(context),
        body: Container(child: loadNetworkContent(displayGame)));
  }

  Game randomGame(Games games) {
    var selectedGame = Random().nextInt(games.games.length);
    return games.games[selectedGame];
  }

  Widget displayGame(BuildContext context, Games games) {
    Game game = randomGame(games);
    return Center(
      child: Container(
        width: getScreenWidthPercentageInPixels(context, ScreenTools.eightyPercentScreen),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppDefaultPadding(
                child: Text(
                  game.name,
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              AppDefaultPadding(
                child: CachedNetworkImage(
                  imageUrl: game.imageUrl,
                  imageBuilder: (context, provider) => Container(
                    height: getScreenHeightPercentageInPixels(
                        context, ScreenTools.fiftyPercentScreen),
                    decoration: BoxDecoration(
                      image: DecorationImage(
                          image: provider, fit: BoxFit.fitHeight),
                    ),
                  ),
                  placeholder: (context, url) => SpinKitCubeGrid(
                      color: Theme.of(context).accentColor,
                      size: getScreenWidthPercentageInPixels(
                          context, ScreenTools.fiftyPercentScreen)),
                  errorWidget: (context, url, error) => new Icon(Icons.error),
                ),
              ),
              shareButton(context, game),
            ]),
      ),
    );
  }
}
