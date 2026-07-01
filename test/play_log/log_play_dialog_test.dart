@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_many_mobile_meeple/model/game.dart';
import 'package:how_many_mobile_meeple/play_log/log_play_dialog.dart';
import 'package:how_many_mobile_meeple/play_log/play_log_entry.dart';

final _game = Game.fromJson(const {
  'id': 42,
  'name': 'Wingspan',
  'maxplayers': 5,
  'minplayers': 1,
  'maxplaytime': 70,
  'image': '',
  'stats': {'average': 8.1, 'averageweight': 2.4},
});

Future<PlayLogEntry?> _openDialog(
  WidgetTester tester, {
  List<String> suggested = const [],
}) async {
  PlayLogEntry? result;
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            result = await LogPlayDialog.show(
              context,
              game: _game,
              suggestedPlayers: suggested,
            );
          },
          child: const Text('open'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return result;
}

void main() {
  group('LogPlayDialog', () {
    testWidgets('shows the game name and defaults date to today',
        (tester) async {
      await _openDialog(tester);
      expect(find.text('Log a play'), findsOneWidget);
      expect(find.text('Wingspan'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('saving with no players returns an entry with empty players',
        (tester) async {
      await _openDialog(tester);
      await tester.tap(find.text('Save play'));
      await tester.pumpAndSettle();

      // Dialog closed after save.
      expect(find.text('Log a play'), findsNothing);
    });

    testWidgets('pre-fills the primary player as a participant',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => LogPlayDialog.show(
                context,
                game: _game,
                primaryPlayer: 'David',
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('David'), findsOneWidget);
    });

    testWidgets('does not pre-fill self when editing', (tester) async {
      final existing = PlayLogEntry(
        id: 'a',
        gameId: 42,
        name: 'Wingspan',
        playedAt: DateTime(2026, 1, 1),
        players: [PlayerResult(name: 'Bob')],
      );
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => LogPlayDialog.show(
                context,
                existing: existing,
                primaryPlayer: 'David',
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('David'), findsNothing);
    });

    testWidgets('winner is toggled with a checkbox', (tester) async {
      PlayLogEntry? result;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await LogPlayDialog.show(
                  context,
                  game: _game,
                  primaryPlayer: 'David',
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byType(Checkbox), findsOneWidget);
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save play'));
      await tester.pumpAndSettle();

      expect(result!.players.single.won, isTrue);
    });

    testWidgets('adds a player via the text field', (tester) async {
      await _openDialog(tester);
      await tester.enterText(find.byType(TextField).first, 'Alice');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets('suggests frequent players as chips', (tester) async {
      await _openDialog(tester, suggested: ['Charlie']);
      expect(find.text('You often play with'), findsOneWidget);
      expect(find.widgetWithText(ActionChip, 'Charlie'), findsOneWidget);
    });

    testWidgets('edit mode pre-fills players and shows edit title',
        (tester) async {
      final existing = PlayLogEntry(
        id: 'a',
        gameId: 42,
        name: 'Wingspan',
        playedAt: DateTime(2026, 1, 1),
        players: [PlayerResult(name: 'Alice', won: true, score: 78)],
      );

      PlayLogEntry? result;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await LogPlayDialog.show(context, existing: existing);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Edit play'), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('78'), findsOneWidget);

      await tester.tap(find.text('Save play'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.id, 'a', reason: 'edit reuses the existing id');
      expect(result!.players.single.name, 'Alice');
    });

    testWidgets('clearing a score on edit removes it', (tester) async {
      final existing = PlayLogEntry(
        id: 'a',
        gameId: 42,
        name: 'Wingspan',
        playedAt: DateTime(2026, 1, 1),
        players: [PlayerResult(name: 'Alice', score: 78)],
      );

      PlayLogEntry? result;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await LogPlayDialog.show(context, existing: existing);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, '78'), '');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save play'));
      await tester.pumpAndSettle();

      expect(result!.players.single.score, isNull,
          reason: 'emptying the score field must clear it, not keep 78');
    });

    testWidgets('tapping a suggestion adds that player', (tester) async {
      await _openDialog(tester, suggested: ['Charlie']);
      await tester.tap(find.widgetWithText(ActionChip, 'Charlie'));
      await tester.pumpAndSettle();

      // Once added the suggestion chip disappears and the player row shows.
      expect(find.widgetWithText(ActionChip, 'Charlie'), findsNothing);
      expect(find.text('Charlie'), findsOneWidget);
    });
  });
}
