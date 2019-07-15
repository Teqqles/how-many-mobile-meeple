import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:scoped_multi_example/screen_tools.dart';

import 'app_default_padding.dart';
import 'app_page.dart';
import 'game_config.dart';
import 'how_many_meeple_app_bar.dart';
import 'load_games.dart';
import 'model.dart';

class RandomGameDisplayPage extends StatelessWidget with ScreenTools, AppPage {
  static final String route = "Display-page";

  static const String findingGames = "Finding games to play";
  static const String speedDisclaimer =
      "this may take some time as board game geek is slow";
  static const String pageErrorNoItemsSupplied =
      "You must provide at least one geeklist or user collection";
  static const String pageErrorOneOrMoreItemsInvalid =
      "One or more of your geeklists or user collections cannot be loaded";
  static const String pageErrorNoGamesAvailable =
      "Your filters have eliminated all games, try relaxing them to be able to select a game";

  static const double fiftyPercentScreen = 0.5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HowManyMeepleAppBar(GameConfig.randomGamePageTitle),
      floatingActionButton: floatingRandomGameButton(context),
      body: Container(
        child: ScopedModelDescendant<AppModel>(
          builder: (context, child, model) {
            if (model.items.isEmpty) {
              return pageErrors(context, pageErrorNoItemsSupplied);
            }
            return FutureBuilder<Games>(
              future: LoadGames.fetchGames(model.settings, model.items),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return gameDataResponse(snapshot, context);
                } else if (snapshot.hasError) {
                  return pageErrors(context, pageErrorOneOrMoreItemsInvalid);
                }
                // By default, show a loading spinner.
                return pageFrameOutline(context, loadingSpinner(context));
              },
            );
          },
        ),
      ),
    );
  }

  Widget gameDataResponse(AsyncSnapshot<Games> snapshot, BuildContext context) {
    if (snapshot.data.games.isEmpty) {
      return pageErrors(context, pageErrorNoGamesAvailable);
    }
    return displayGame(context, randomGame(snapshot.data));
  }

  Game randomGame(Games games) {
    var selectedGame = Random().nextInt(games.games.length);
    return games.games[selectedGame];
  }

  Widget displayGame(BuildContext context, Game game) {
    return Center(
      child: Container(
        width: getScreenWidthPercentageInPixels(context, 0.8),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppDefaultPadding(
                child: CachedNetworkImage(
                  imageUrl: game.imageUrl,
                  imageBuilder: (context, provider) => Container(
                    height: getScreenHeightPercentageInPixels(
                        context, fiftyPercentScreen),
                    decoration: BoxDecoration(
                      image: DecorationImage(
                          image: provider, fit: BoxFit.fitHeight),
                    ),
                  ),
                  placeholder: (context, url) => SpinKitCubeGrid(
                      color: Theme.of(context).accentColor,
                      size: getScreenWidthPercentageInPixels(
                          context, fiftyPercentScreen)),
                  errorWidget: (context, url, error) => new Icon(Icons.error),
                ),
              ),
              Text(
                game.name,
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ]),
      ),
    );
  }

  Widget pageErrors(BuildContext context, String error) {
    return Center(
      child: Container(
        width: getScreenWidthPercentageInPixels(context, fiftyPercentScreen),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AppDefaultPadding(
                child: Icon(Icons.error,
                    color: Theme.of(context).errorColor,
                    size: getScreenWidthPercentageInPixels(
                        context, fiftyPercentScreen)),
              ),
              Text(
                error,
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ]),
      ),
    );
  }

  Widget loadingSpinner(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      AppDefaultPadding(
        child: SpinKitCubeGrid(
            color: Theme.of(context).accentColor,
            size:
                getScreenWidthPercentageInPixels(context, fiftyPercentScreen)),
      ),
      Text(findingGames, style: TextStyle(fontWeight: FontWeight.bold)),
      Text(
        speedDisclaimer,
        style: TextStyle(fontSize: 12),
      )
    ]);
  }

  Row pageFrameOutline(BuildContext context, Widget frameContent) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [frameContent],
    );
  }
}
