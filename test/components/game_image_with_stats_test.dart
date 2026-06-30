@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_many_mobile_meeple/components/game_image_with_stats.dart';
import 'package:how_many_mobile_meeple/model/game.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Game _gameWithRating(double rating) => Game(
      id: 1,
      name: 'Test Game',
      maxPlayers: 4,
      minPlayers: 2,
      maxPlaytime: 60,
      imageUrl: 'http://example.com/test.jpg',
      averageRating: rating,
      averageWeight: 2.5,
    );

Game _gameWithNoData() => Game(
      id: 1,
      name: 'Mystery Game',
      maxPlayers: 0,
      minPlayers: 0,
      maxPlaytime: 0,
      imageUrl: '',
      averageRating: 0,
      averageWeight: 0,
    );

Game _gameWithPartialData() => Game(
      id: 1,
      name: 'Partial Game',
      maxPlayers: 4,
      minPlayers: 2,
      maxPlaytime: 0,
      imageUrl: 'http://example.com/test.jpg',
      averageRating: 7.5,
      averageWeight: 0,
    );

Widget _wrapWidget(Widget child) => ChangeNotifierProvider<AppModel>.value(
      value: AppModel(),
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 400, height: 600, child: child),
        ),
      ),
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('GameImageWithStats rating badge', () {
    setUp(() {
      FlutterError.onError = (details) {
        if (details.toString().contains('overflowed')) return;
        FlutterError.presentError(details);
      };
    });

    tearDown(() {
      FlutterError.onError = FlutterError.presentError;
    });

    testWidgets('displays rating text formatted to one decimal place',
        (tester) async {
      await tester.pumpWidget(
        _wrapWidget(GameImageWithStats(game: _gameWithRating(7.83))),
      );

      expect(find.text('7.8'), findsOneWidget);
    });

    testWidgets('gold star for rating >= 7.5', (tester) async {
      await tester.pumpWidget(
        _wrapWidget(GameImageWithStats(game: _gameWithRating(7.5))),
      );

      expect(find.text('7.5'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('silver star for rating >= 6.5', (tester) async {
      await tester.pumpWidget(
        _wrapWidget(GameImageWithStats(game: _gameWithRating(6.8))),
      );

      expect(find.text('6.8'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('bronze star for rating >= 5.5', (tester) async {
      await tester.pumpWidget(
        _wrapWidget(GameImageWithStats(game: _gameWithRating(5.9))),
      );

      expect(find.text('5.9'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('orange circle for rating >= 4.5', (tester) async {
      await tester.pumpWidget(
        _wrapWidget(GameImageWithStats(game: _gameWithRating(4.7))),
      );

      expect(find.text('4.7'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('red circle for rating < 4.5', (tester) async {
      await tester.pumpWidget(
        _wrapWidget(GameImageWithStats(game: _gameWithRating(3.2))),
      );

      expect(find.text('3.2'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('boundary: 7.4 gets silver not gold', (tester) async {
      await tester.pumpWidget(
        _wrapWidget(GameImageWithStats(game: _gameWithRating(7.4))),
      );

      expect(find.text('7.4'), findsOneWidget);
    });

    testWidgets('boundary: 4.4 gets red not orange', (tester) async {
      await tester.pumpWidget(
        _wrapWidget(GameImageWithStats(game: _gameWithRating(4.4))),
      );

      expect(find.text('4.4'), findsOneWidget);
    });
  });

  group('GameImageWithStats hides missing data', () {
    setUp(() {
      FlutterError.onError = (details) {
        if (details.toString().contains('overflowed')) return;
        FlutterError.presentError(details);
      };
    });

    tearDown(() {
      FlutterError.onError = FlutterError.presentError;
    });

    testWidgets('hides rating badge when rating is 0', (tester) async {
      await tester.pumpWidget(
        _wrapWidget(GameImageWithStats(game: _gameWithNoData())),
      );

      expect(find.text('0.0'), findsNothing);
    });

    testWidgets('hides player count when both min and max are 0',
        (tester) async {
      await tester.pumpWidget(
        _wrapWidget(GameImageWithStats(game: _gameWithNoData())),
      );

      expect(find.byIcon(Icons.people), findsNothing);
    });

    testWidgets('hides playtime when maxPlaytime is 0', (tester) async {
      await tester.pumpWidget(
        _wrapWidget(GameImageWithStats(game: _gameWithNoData())),
      );

      expect(find.byIcon(Icons.timer), findsNothing);
    });

    testWidgets('hides weight when averageWeight is 0', (tester) async {
      await tester.pumpWidget(
        _wrapWidget(GameImageWithStats(game: _gameWithNoData())),
      );

      expect(find.byIcon(Icons.fitness_center), findsNothing);
    });

    testWidgets('always shows BoardGameGeek link', (tester) async {
      await tester.pumpWidget(
        _wrapWidget(GameImageWithStats(game: _gameWithNoData())),
      );

      expect(find.byIcon(Icons.open_in_new), findsOneWidget);
    });

    testWidgets('shows only stats that have data', (tester) async {
      await tester.pumpWidget(
        _wrapWidget(GameImageWithStats(game: _gameWithPartialData())),
      );

      expect(find.byIcon(Icons.people), findsOneWidget);
      expect(find.byIcon(Icons.timer), findsNothing);
      expect(find.byIcon(Icons.fitness_center), findsNothing);
      expect(find.byIcon(Icons.open_in_new), findsOneWidget);
    });
  });
}
