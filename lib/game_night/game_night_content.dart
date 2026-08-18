import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:how_many_mobile_meeple/game_night/game_night_view.dart';
import 'package:how_many_mobile_meeple/guided_flow/step1_select_source.dart';
import 'package:how_many_mobile_meeple/load_games.dart';
import 'package:how_many_mobile_meeple/model/game_night.dart';
import 'package:how_many_mobile_meeple/model/game_request.dart';
import 'package:how_many_mobile_meeple/model/games.dart';
import 'package:how_many_mobile_meeple/model/model.dart';

/// Fetches the game-night pool - the collection with per-game duration filters
/// removed so the evening budget alone governs playtime - and hands it to the
/// [GameNightView] planner. The single-game recommendation cache cannot be
/// reused because that request carries the duration filters this mode drops.
///
/// The same source picker as the one-game flow is available from this page, so
/// sources can be added or changed without leaving Game Night. The pool
/// refetches whenever the sources (or other filters) change.
class GameNightContent extends StatefulWidget {
  final AppModel model;
  final GameNightPlanner? planner;

  const GameNightContent({super.key, required this.model, this.planner});

  @override
  State<GameNightContent> createState() => _GameNightContentState();
}

class _GameNightContentState extends State<GameNightContent> {
  Future<Games>? _pool;
  GameRequest? _poolRequest;

  @override
  Widget build(BuildContext context) {
    if (widget.model.items.itemList.isEmpty) {
      // Drop the stale pool so re-adding a source triggers a fresh fetch.
      _pool = null;
      _poolRequest = null;
      return const SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 16),
        child: Step1SelectSource(),
      );
    }

    final request = widget.model.buildGameNightRequest();
    if (_pool == null || request != _poolRequest) {
      _pool = LoadGames.fetchGames(request);
      _poolRequest = request;
    }

    return Column(
      children: [
        _buildSourcesPanel(context),
        Expanded(
          child: FutureBuilder<Games>(
            future: _pool,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _message(
                  context,
                  'Could not load your games. Check your connection and '
                  'try again.',
                );
              }
              if (!snapshot.hasData) {
                return Center(
                  child: SpinKitCubeGrid(
                    size: 64,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                );
              }
              return GameNightView(
                model: widget.model,
                pool: snapshot.data!.games,
                planner: widget.planner,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSourcesPanel(BuildContext context) {
    final count = widget.model.items.itemList.length;
    return Card(
      margin: const EdgeInsets.fromLTRB(10, 12, 10, 0),
      child: ExpansionTile(
        leading: const Icon(Icons.source),
        title: const Text('Sources'),
        subtitle: Text('$count added - tap to add or change'),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        children: const [Step1SelectSource()],
      ),
    );
  }

  Widget _message(BuildContext context, String text) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(text, textAlign: TextAlign.center),
    ),
  );
}
