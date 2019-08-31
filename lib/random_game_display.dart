import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:how_many_mobile_meeple/screen_tools.dart';

import 'package:how_many_mobile_meeple/components/app_default_padding.dart';
import 'app_page.dart';
import 'package:how_many_mobile_meeple/model/bgg_cache.dart';
import 'app_common.dart';
import 'how_many_meeple_app_bar.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'model/game.dart';
import 'network_content_widget.dart';

class RandomGameDisplayPage extends NetworkWidget with AppPage {
  static final String route = "Random-game-page";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: HowManyMeepleAppBar(AppCommon.randomGamePageTitle),
        persistentFooterButtons: [iconButtonGroup(context)],
        body: Container(child: loadNetworkContent(displayGame)));
  }

  Widget displayGame(
      BuildContext context, AppModel model, BggCache cachedGames) {
    Game game = cachedGames.lastRandom;
    if (model.screenOrientation == null ||
        model.screenOrientation == MediaQuery.of(context).orientation) {
      game = cachedGames.random;
    }
    model.screenOrientation = MediaQuery.of(context).orientation;
    return Center(
      child: Container(
        width: getScreenWidthPercentageInPixels(
            context, ScreenTools.eightyPercentScreen),
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
                  errorWidget: (context, url, error) => Icon(Icons.error),
                ),
              ),
              shareButton(context, game),
            ]),
      ),
    );
  }
}
