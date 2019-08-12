import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:how_many_mobile_meeple/screen_tools.dart';

import 'app_default_padding.dart';
import 'package:how_many_mobile_meeple/model/bgg_cache.dart';
import 'load_games.dart';
import 'package:how_many_mobile_meeple/model/model.dart';

import 'model/games.dart';

abstract class NetworkWidget extends StatelessWidget with ScreenTools {
  static const String speedDisclaimer =
      "this may take some time as board game geek is slow";
  static const String pageErrorNoItemsSupplied =
      "You must provide at least one geeklist or user collection";
  static const String pageErrorOneOrMoreItemsInvalid =
      "One or more of your geeklists or user collections cannot be loaded";
  static const String pageErrorNoGamesAvailable =
      "Your filters have eliminated all games, try relaxing them to be able to select a game";

  static const String findingGames = "Finding games to play";

  Widget pageErrors(BuildContext context, String error) {
    return Center(
      child: Container(
        width: getScreenWidthPercentageInPixels(
            context, ScreenTools.fiftyPercentScreen),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AppDefaultPadding(
                child: Icon(Icons.error,
                    color: Theme.of(context).errorColor,
                    size: getScreenWidthPercentageInPixels(
                        context, ScreenTools.fiftyPercentScreen)),
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
            size: getScreenWidthPercentageInPixels(
                context, ScreenTools.fiftyPercentScreen)),
      ),
      Text(findingGames, style: TextStyle(fontWeight: FontWeight.bold)),
      Text(
        speedDisclaimer,
        style: TextStyle(fontSize: 12),
      )
    ]);
  }

  Widget gameDataResponse(
      AppModel model,
      AsyncSnapshot<Games> snapshot,
      BuildContext context,
      Widget displayWidgetFn(
          BuildContext context, AppModel model, BggCache cachedGames)) {
    if (snapshot.data.games.isEmpty) {
      return pageErrors(context, pageErrorNoGamesAvailable);
    }
    model.replaceCache(snapshot.data);
    return displayWidgetFn(context, model, model.bggCache);
  }

  Widget loadNetworkContent(
      Widget displayWidgetFn(
          BuildContext context, AppModel model, BggCache cachedGames)) {
    return ScopedModelDescendant<AppModel>(
      builder: (context, child, model) {
        if (model.items.isEmpty) {
          return pageErrors(context, pageErrorNoItemsSupplied);
        }
        return contentFromNetworkOrCache(context, model, displayWidgetFn);
      },
    );
  }

  Widget contentFromNetworkOrCache(
      BuildContext context,
      AppModel model,
      Widget displayWidgetFn(
          BuildContext context, AppModel model, BggCache cachedGames)) {
    if (!model.bggCache.isStale()) {
      return displayWidgetFn(context, model, model.bggCache);
    }
    return FutureBuilder<Games>(
      future: LoadGames.fetchGames(model.settings, model.items.itemList),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return gameDataResponse(model, snapshot, context, displayWidgetFn);
        } else if (snapshot.hasError) {
          return pageErrors(context, pageErrorOneOrMoreItemsInvalid);
        }
        // By default, show a loading spinner.
        return pageFrameOutline(context, loadingSpinner(context));
      },
    );
  }
}
