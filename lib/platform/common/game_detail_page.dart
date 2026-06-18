import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:how_many_mobile_meeple/api/game_detail_service.dart';
import 'package:how_many_mobile_meeple/components/app_default_padding.dart';
import 'package:how_many_mobile_meeple/components/game_image_with_stats.dart';
import 'package:how_many_mobile_meeple/components/recommendations_widget.dart';
import 'package:how_many_mobile_meeple/how_many_meeple_app_bar.dart';
import 'package:how_many_mobile_meeple/model/game.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/screen_tools.dart';
import 'package:how_many_mobile_meeple/app_page.dart';

class GameDetailPage extends StatefulWidget {
  final int gameId;

  const GameDetailPage({super.key, required this.gameId});

  @override
  State<GameDetailPage> createState() => _GameDetailPageState();
}

class _GameDetailPageState extends State<GameDetailPage>
    with ScreenTools, AppPage {
  late Future<Game> _future;

  @override
  void initState() {
    super.initState();
    _future = GameDetailService.fetchGame(widget.gameId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HowManyMeepleAppBar('Game Details', context: context),
      endDrawer: pageDrawer(context),
      persistentFooterButtons: [iconButtonGroup(context)],
      body: FutureBuilder<Game>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load game'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return _buildGameDisplay(context, snapshot.data!);
        },
      ),
    );
  }

  Widget _buildGameDisplay(BuildContext context, Game game) {
    final model = Provider.of<AppModel>(context, listen: false);
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
              shareButton(context, game),
              RecommendationsWidget(sourceGame: game, model: model),
            ],
          ),
        ),
      ),
    );
  }
}
