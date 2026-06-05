import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:how_many_mobile_meeple/screen_tools.dart';

import 'package:how_many_mobile_meeple/components/app_default_padding.dart';
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
    // Constrain icon to reasonable size (max 200px or 50% of screen width, whichever is smaller)
    final iconSize = getScreenWidthPercentageInPixels(
            context, ScreenTools.fiftyPercentScreen)
        .clamp(0.0, 200.0);

    return Center(
      child: Container(
        width: getScreenWidthPercentageInPixels(
            context, ScreenTools.fiftyPercentScreen),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppDefaultPadding(
                child: Icon(Icons.error,
                    color: Theme.of(context).colorScheme.error, size: iconSize),
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
    // Constrain spinner to reasonable size (max 200px or 50% of screen width, whichever is smaller)
    final spinnerSize = getScreenWidthPercentageInPixels(
            context, ScreenTools.fiftyPercentScreen)
        .clamp(0.0, 200.0);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppDefaultPadding(
            child: SpinKitCubeGrid(
                color: Theme.of(context).colorScheme.secondary,
                size: spinnerSize),
          ),
          Text(findingGames, style: TextStyle(fontWeight: FontWeight.bold)),
          Text(
            speedDisclaimer,
            style: TextStyle(fontSize: 12),
          )
        ],
      ),
    );
  }

  Widget gameDataResponse(
      AppModel model,
      AsyncSnapshot<Games> snapshot,
      BuildContext context,
      Widget displayWidgetFn(BuildContext context, AppModel model)) {
    if (snapshot.data!.games.isEmpty) {
      return pageErrors(context, pageErrorNoGamesAvailable);
    }
    model.replaceCache(snapshot.data!);
    return displayWidgetFn(context, model);
  }

  Widget loadNetworkContent(
      Widget displayWidgetFn(BuildContext context, AppModel model)) {
    return Consumer<AppModel>(builder: (context, model, child) {
      if (model.items.isEmpty) {
        return pageErrors(context, pageErrorNoItemsSupplied);
      }
      return contentFromNetworkOrCache(context, model, displayWidgetFn);
    });
  }

  Widget contentFromNetworkOrCache(BuildContext context, AppModel model,
      Widget displayWidgetFn(BuildContext context, AppModel model)) {
    if (!model.bggCache.isStale()) {
      return displayWidgetFn(context, model);
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
