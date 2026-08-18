@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_many_mobile_meeple/favourites/favourite_game.dart';
import 'package:how_many_mobile_meeple/favourites/ignored_games_service.dart';
import 'package:how_many_mobile_meeple/game_night/game_night_view.dart';
import 'package:how_many_mobile_meeple/model/game.dart';
import 'package:how_many_mobile_meeple/model/game_night.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/model/play_data.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

Game _game(
  int id,
  String name,
  int maxPlaytime,
  double weight, {
  List<String> mechanics = const [],
}) => Game(
  id: id,
  name: name,
  maxPlayers: 4,
  minPlayers: 2,
  maxPlaytime: maxPlaytime,
  imageUrl: '',
  averageRating: 7,
  averageWeight: weight,
  mechanics: mechanics,
);

List<Game> _pool() => [
  _game(1, 'Quick', 15, 2.0),
  _game(2, 'Epic', 120, 3.5),
  _game(3, 'Mid', 60, 2.5),
  _game(4, 'Alt', 100, 1.5),
];

AppModel _modelWithDuration(int minutes) {
  final model = AppModel();
  final duration = model.settings.setting(
    Settings.gameNightDurationMinutes.name,
  )..value = minutes;
  model.settings.updateSetting(duration);
  return model;
}

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
  tearDown(IgnoredGamesService.resetForTesting);

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

  testWidgets('shows play counts once plays are loaded', (tester) async {
    final model = AppModel()
      ..setPlaysForTest(
        playsData: {2: PlayData(gameId: 2, gameName: 'Epic', totalPlays: 3)},
        collectionGameIds: {2},
      );

    await tester.pumpWidget(_wrap(model));

    expect(find.text('Played 3×'), findsOneWidget);
    expect(find.text('Unplayed'), findsWidgets);
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

  testWidgets('play-history filter appears only once plays are loaded', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(AppModel()));
    expect(find.text('Play history'), findsNothing);

    final model = AppModel()
      ..setPlaysForTest(playsData: {}, collectionGameIds: {});
    await tester.pumpWidget(_wrap(model));

    expect(find.text('Play history'), findsOneWidget);
  });

  testWidgets('filtering to played narrows the lineup to played games', (
    tester,
  ) async {
    final model = AppModel()
      ..setPlaysForTest(
        playsData: {2: PlayData(gameId: 2, gameName: 'Epic', totalPlays: 3)},
        collectionGameIds: {2},
      );
    await tester.pumpWidget(_wrap(model));
    expect(find.text('Quick'), findsOneWidget);

    await tester.tap(find.text('Played'));
    await tester.pumpAndSettle();

    expect(find.text('Epic'), findsOneWidget);
    expect(find.text('Quick'), findsNothing);
  });

  testWidgets('pins the games carried by a shared lineup', (tester) async {
    final model = AppModel();
    final setting = model.settings.setting(Settings.gameNightLineup.name)
      ..value = '1-2-4-0'
      ..enabled = true;
    model.settings.updateSetting(setting);

    await tester.pumpWidget(_wrap(model));
    await tester.pump();

    // Filler 1, main 2 and backup 4 all arrive pinned.
    expect(find.byIcon(Icons.push_pin), findsNWidgets(3));
    expect(find.byIcon(Icons.push_pin_outlined), findsNothing);
  });

  testWidgets('shows a player count picker defaulting to any', (tester) async {
    await tester.pumpWidget(_wrap(AppModel()));

    expect(find.text('Players'), findsOneWidget);
    expect(find.text('Any'), findsOneWidget);
    for (final count in [1, 2, 3, 4, 5, 6, 7, 8]) {
      expect(find.widgetWithText(ChoiceChip, '$count'), findsOneWidget);
    }
  });

  testWidgets('choosing a player count enables the game-night filter', (
    tester,
  ) async {
    final model = AppModel();
    await tester.pumpWidget(_wrap(model));

    await tester.tap(find.widgetWithText(ChoiceChip, '4'));
    await tester.pump();

    final setting = model.settings.setting(Settings.gameNightPlayerCount.name);
    expect(setting.enabled, isTrue);
    expect(setting.getInt(), 4);
  });

  testWidgets('offers a share action for a filled lineup', (tester) async {
    await tester.pumpWidget(_wrap(AppModel()));

    final share = find.byKey(const ValueKey('game-night-share'));
    expect(share, findsOneWidget);
    expect(tester.widget<OutlinedButton>(share).onPressed, isNotNull);
  });

  testWidgets('hides the mechanic picker when the pool carries no mechanics', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(AppModel()));

    expect(
      find.byKey(const ValueKey('game-night-mechanic-main')),
      findsNothing,
    );
  });

  testWidgets('a slot mechanic narrows that slot to matching games', (
    tester,
  ) async {
    final pool = [
      _game(1, 'Quick', 15, 2.0),
      _game(2, 'Placer', 120, 3.5, mechanics: ['Worker Placement']),
      _game(3, 'Roller', 60, 2.5, mechanics: ['Dice Rolling']),
    ];
    await tester.pumpWidget(_wrap(AppModel(), pool: pool));
    // Placer is the longest fitting game, so it is the default centrepiece.
    expect(find.text('Placer'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('game-night-mechanic-main')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dice Rolling').last);
    await tester.pumpAndSettle();

    expect(find.text('Roller'), findsOneWidget);
    expect(find.text('Placer'), findsNothing);
  });

  testWidgets('never suggests an ignored game', (tester) async {
    final ignored = await IgnoredGamesService.instance();
    ignored.toggle(FavouriteGame(id: 2, name: 'Epic', thumbnail: null));

    await tester.pumpWidget(_wrap(AppModel()));

    // Epic is the longest fitting game, but it is ignored, so the shorter Alt
    // takes the main slot instead and Epic never appears.
    expect(find.text('Epic'), findsNothing);
    expect(find.text('Alt'), findsOneWidget);
  });

  testWidgets('offers the evening-ender toggle only past two hours', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(_modelWithDuration(180)));
    expect(
      find.byKey(const ValueKey('game-night-outro-toggle')),
      findsOneWidget,
    );

    await tester.pumpWidget(_wrap(_modelWithDuration(120)));
    expect(find.byKey(const ValueKey('game-night-outro-toggle')), findsNothing);
  });

  testWidgets(
    'adds a wind-down outro on a long night and lets you disable it',
    (tester) async {
      final pool = [
        _game(1, 'Quick', 15, 2.0),
        _game(2, 'Epic', 120, 3.5),
        _game(3, 'Closer', 20, 2.0),
      ];
      await tester.pumpWidget(_wrap(_modelWithDuration(240), pool: pool));

      expect(find.text('Outro · Wind-down closer'), findsOneWidget);
      expect(find.text('Closer'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('game-night-outro-toggle')));
      await tester.pumpAndSettle();

      expect(find.text('Outro · Wind-down closer'), findsNothing);
      expect(find.text('Closer'), findsNothing);
    },
  );
}
