import 'package:flutter/material.dart';
import 'package:how_many_mobile_meeple/components/game_image_with_stats.dart';
import 'package:how_many_mobile_meeple/components/recommendations_widget.dart';
import 'package:how_many_mobile_meeple/favourites/game_action_buttons.dart';
import 'package:how_many_mobile_meeple/favourites/ignored_games_service.dart';
import 'package:how_many_mobile_meeple/platform/common/game_display_page.dart';
import 'package:how_many_mobile_meeple/platform/router.dart' as r;
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
        appBar: HowManyMeepleAppBar(AppCommon.randomGamePageTitle,
            context: context),
        endDrawer: pageDrawer(context),
        persistentFooterButtons: [iconButtonGroup(context)],
        body: Container(child: loadNetworkContent(displayGame)));
  }

  Widget displayGame(BuildContext context, AppModel model) {
    var cachedGames = model.bggCache;
    Game? game =
        hasPageRefreshed(model) ? cachedGames.random : cachedGames.lastRandom;
    if (game == null) {
      return _buildExhaustedState(context, model);
    }
    updatePageRefreshedStatus(model);
    return SingleChildScrollView(
      child: Center(
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
                AppDefaultPadding(child: GameImageWithStats(game: game)),
                GameActionButtons(game: game),
                RecommendationsWidget(sourceGame: game, model: model),
              ]),
        ),
      ),
    );
  }

  Widget _buildExhaustedState(BuildContext context, AppModel model) {
    final hasIgnored = (IgnoredGamesService.cached?.games.length ?? 0) > 0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.casino_outlined,
                size: 64, color: Theme.of(context).colorScheme.secondary),
            const SizedBox(height: 16),
            Text(
              "You've seen all available games",
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (hasIgnored) ...[
              const SizedBox(height: 12),
              Text(
                'Want to try again including your ignored games?',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  final game = model.bggCache.randomIncludingIgnored();
                  if (game != null) {
                    Navigator.of(context).pushReplacementNamed(
                        '${r.Router.gameDetailRoute}/${game.name.replaceAll(' ', '+')}/${game.id}');
                  }
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Include ignored games'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
