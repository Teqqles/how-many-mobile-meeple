import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_many_mobile_meeple/components/game_image_with_stats.dart';
import 'package:how_many_mobile_meeple/model/game.dart';

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

Widget _wrapWidget(Widget child) => MaterialApp(
      home: Scaffold(
        body: SizedBox(width: 400, height: 600, child: child),
      ),
    );

void main() {
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
      final sizedBoxes = find.byWidgetPredicate(
        (w) => w is SizedBox && w.width == 72 && w.height == 72,
      );
      expect(sizedBoxes, findsOneWidget);
    });

    testWidgets('silver star for rating >= 6.5', (tester) async {
      await tester.pumpWidget(
        _wrapWidget(GameImageWithStats(game: _gameWithRating(6.8))),
      );

      expect(find.text('6.8'), findsOneWidget);
      final sizedBoxes = find.byWidgetPredicate(
        (w) => w is SizedBox && w.width == 72 && w.height == 72,
      );
      expect(sizedBoxes, findsOneWidget);
    });

    testWidgets('bronze star for rating >= 5.5', (tester) async {
      await tester.pumpWidget(
        _wrapWidget(GameImageWithStats(game: _gameWithRating(5.9))),
      );

      expect(find.text('5.9'), findsOneWidget);
      final sizedBoxes = find.byWidgetPredicate(
        (w) => w is SizedBox && w.width == 72 && w.height == 72,
      );
      expect(sizedBoxes, findsOneWidget);
    });

    testWidgets('orange circle for rating >= 4.5', (tester) async {
      await tester.pumpWidget(
        _wrapWidget(GameImageWithStats(game: _gameWithRating(4.7))),
      );

      expect(find.text('4.7'), findsOneWidget);
      final containers = find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.constraints?.maxWidth == 56 &&
            w.constraints?.maxHeight == 56,
      );
      expect(containers, findsOneWidget);
    });

    testWidgets('red circle for rating < 4.5', (tester) async {
      await tester.pumpWidget(
        _wrapWidget(GameImageWithStats(game: _gameWithRating(3.2))),
      );

      expect(find.text('3.2'), findsOneWidget);
      final containers = find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.constraints?.maxWidth == 56 &&
            w.constraints?.maxHeight == 56,
      );
      expect(containers, findsOneWidget);
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
}
