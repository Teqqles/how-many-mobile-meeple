@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_many_mobile_meeple/game_night/game_night_view.dart';
import 'package:how_many_mobile_meeple/model/game.dart';
import 'package:how_many_mobile_meeple/model/game_night.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:shared_preferences/shared_preferences.dart';

Game _game(int id, String name, int maxPlaytime, double weight) => Game(
  id: id,
  name: name,
  maxPlayers: 4,
  minPlayers: 2,
  maxPlaytime: maxPlaytime,
  imageUrl: '',
  averageRating: 7,
  averageWeight: weight,
);

List<Game> _pool() => [
  _game(1, 'Quick', 15, 2.0),
  _game(2, 'Epic', 120, 3.5),
  _game(3, 'Mid', 60, 2.5),
  _game(4, 'Alt', 100, 1.5),
];

Widget _wrap(AppModel model, {List<Game>? pool}) => MaterialApp(
  home: Scaffold(
    body: GameNightView(
      model: model,
      pool: pool ?? _pool(),
      planner: GameNightPlanner(pick: (_) => 0),
    ),
  ),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('fills filler, main and backup from the pool', (tester) async {
    await tester.pumpWidget(_wrap(AppModel()));

    // Filler is the short game; main is the longest that fits 180 - 15; backup
    // is a similarly-timed game in a different complexity band.
    expect(find.text('Quick'), findsOneWidget);
    expect(find.text('Epic'), findsOneWidget);
    expect(find.text('Alt'), findsOneWidget);
    expect(find.text('Main · The centrepiece'), findsOneWidget);
  });

  testWidgets('prompts to load a collection when the pool is empty', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(AppModel(), pool: const []));

    expect(find.textContaining('Load a collection'), findsOneWidget);
  });

  testWidgets('offers a regenerate action', (tester) async {
    await tester.pumpWidget(_wrap(AppModel()));

    expect(find.byKey(const ValueKey('game-night-regenerate')), findsOneWidget);
  });

  testWidgets('shows duration presets', (tester) async {
    await tester.pumpWidget(_wrap(AppModel()));

    expect(find.text('2h'), findsOneWidget);
    expect(find.text('4h'), findsOneWidget);
    expect(find.text('5h'), findsOneWidget);
    // 3h is both the default preset chip and the slider readout.
    expect(find.text('3h'), findsNWidgets(2));
  });

  testWidgets('shows game details for a filled slot', (tester) async {
    await tester.pumpWidget(_wrap(AppModel()));

    expect(find.text('120 min'), findsOneWidget);
    expect(find.text('2-4 players'), findsWidgets);
  });

  testWidgets('re-plans when a new pool arrives', (tester) async {
    final model = AppModel();
    await tester.pumpWidget(_wrap(model));
    expect(find.text('Epic'), findsOneWidget);

    await tester.pumpWidget(
      _wrap(
        model,
        pool: [_game(8, 'Warmup', 20, 2.0), _game(9, 'Titan', 150, 3.0)],
      ),
    );
    await tester.pump();

    expect(find.text('Titan'), findsOneWidget);
    expect(find.text('Epic'), findsNothing);
  });

  testWidgets('pinning a slot marks it pinned', (tester) async {
    await tester.pumpWidget(_wrap(AppModel()));

    expect(find.byIcon(Icons.push_pin), findsNothing);
    await tester.tap(find.byIcon(Icons.push_pin_outlined).first);
    await tester.pump();

    expect(find.byIcon(Icons.push_pin), findsOneWidget);
  });
}
