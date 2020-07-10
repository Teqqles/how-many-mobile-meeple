import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:how_many_mobile_meeple/components/platform_independent_image.dart';
import 'package:how_many_mobile_meeple/platform/common/game_display_page.dart';
import 'package:how_many_mobile_meeple/screen_tools.dart';

import 'package:how_many_mobile_meeple/components/app_default_padding.dart';
import '../../app_common.dart';
import '../../how_many_meeple_app_bar.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import '../../model/game.dart';

class WebRandomGameDisplayPage extends GameDisplayPage {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: HowManyMeepleAppBar(AppCommon.randomGamePageTitle, context: context),
        persistentFooterButtons: [iconButtonGroup(context)],
        body: Container(child: loadNetworkContent(displayGame)));
  }

  Widget displayGame(
      BuildContext context, AppModel model) {
    var cachedGames = model.bggCache;
    Game game = hasPageRefreshed(model) ? cachedGames.random : cachedGames.lastRandom;
    updatePageRefreshedStatus(model);
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
                child: PlatformIndependentImage(imageUrl: game.imageUrl)
              ),
            ]),
      ),
    );
  }
}
