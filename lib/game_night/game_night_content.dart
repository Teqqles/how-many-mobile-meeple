import 'package:flutter/material.dart';
import 'package:how_many_mobile_meeple/game_night/game_night_view.dart';
import 'package:how_many_mobile_meeple/model/game_night.dart';
import 'package:how_many_mobile_meeple/network_content_widget.dart';

/// Fetches the server-filtered game pool - exactly as the single-game flow
/// does - before handing it to the [GameNightView] planner. Without this the
/// planner reads an empty cache whenever a collection is loaded but no
/// recommendation has been requested yet.
class GameNightContent extends NetworkWidget {
  final GameNightPlanner? planner;

  GameNightContent({this.planner});

  @override
  Widget build(BuildContext context) {
    return loadNetworkContent(
      (context, model) => GameNightView(model: model, planner: planner),
    );
  }
}
