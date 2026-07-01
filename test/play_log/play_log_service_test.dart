@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:how_many_mobile_meeple/play_log/play_log_entry.dart';
import 'package:how_many_mobile_meeple/play_log/play_log_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PlayLogService.resetForTesting();
    SharedPreferences.setMockInitialValues({});
  });

  PlayLogEntry entry(
    String id,
    int gameId,
    DateTime playedAt, {
    String name = 'Game',
    List<PlayerResult> players = const [],
  }) =>
      PlayLogEntry(
        id: id,
        gameId: gameId,
        name: name,
        playedAt: playedAt,
        players: players,
      );

  group('PlayLogService', () {
    test('starts empty', () async {
      final service = await PlayLogService.instance();
      expect(service.entries, isEmpty);
    });

    test('logPlay adds an entry', () async {
      final service = await PlayLogService.instance();
      service.logPlay(entry('a', 1, DateTime(2026, 1, 1)));
      expect(service.entries.length, 1);
    });

    test('allows the same game to be logged multiple times', () async {
      final service = await PlayLogService.instance();
      service.logPlay(entry('a', 1, DateTime(2026, 1, 1)));
      service.logPlay(entry('b', 1, DateTime(2026, 2, 1)));
      expect(service.entries.length, 2);
      expect(service.playCount(1), 2);
    });

    test('entries are ordered newest first', () async {
      final service = await PlayLogService.instance();
      service.logPlay(entry('old', 1, DateTime(2026, 1, 1)));
      service.logPlay(entry('new', 2, DateTime(2026, 6, 1)));
      expect(service.entries.first.id, 'new');
      expect(service.entries.last.id, 'old');
    });

    test('remove deletes an entry by id', () async {
      final service = await PlayLogService.instance();
      service.logPlay(entry('a', 1, DateTime(2026, 1, 1)));
      service.logPlay(entry('b', 2, DateTime(2026, 2, 1)));
      service.remove('a');
      expect(service.entries.length, 1);
      expect(service.entries.first.id, 'b');
    });

    test('lastPlayed returns most recent play for a game', () async {
      final service = await PlayLogService.instance();
      service.logPlay(entry('a', 1, DateTime(2026, 1, 1)));
      service.logPlay(entry('b', 1, DateTime(2026, 3, 1)));
      expect(service.lastPlayed(1), DateTime(2026, 3, 1));
    });

    test('lastPlayed returns null for a game never played', () async {
      final service = await PlayLogService.instance();
      expect(service.lastPlayed(99), isNull);
    });

    test('playCount returns zero for unknown game', () async {
      final service = await PlayLogService.instance();
      expect(service.playCount(99), 0);
    });

    test('frequentPlayers orders by appearance count', () async {
      final service = await PlayLogService.instance();
      service.logPlay(entry('a', 1, DateTime(2026, 1, 1), players: [
        PlayerResult(name: 'Alice'),
        PlayerResult(name: 'Bob'),
      ]));
      service.logPlay(entry('b', 1, DateTime(2026, 2, 1), players: [
        PlayerResult(name: 'Alice'),
      ]));
      final frequent = service.frequentPlayers();
      expect(frequent.first, 'Alice');
      expect(frequent, containsAll(['Alice', 'Bob']));
    });

    test('update replaces an entry by id', () async {
      final service = await PlayLogService.instance();
      service.logPlay(entry('a', 1, DateTime(2026, 1, 1), name: 'Catan'));
      service
          .update(entry('a', 1, DateTime(2026, 1, 1), name: 'Catan', players: [
        PlayerResult(name: 'Alice', won: true),
      ]));
      expect(service.entries.length, 1);
      expect(service.entries.first.players.single.name, 'Alice');
    });

    test('update re-sorts when the date changes', () async {
      final service = await PlayLogService.instance();
      service.logPlay(entry('a', 1, DateTime(2026, 1, 1)));
      service.logPlay(entry('b', 2, DateTime(2026, 2, 1)));
      // Move 'a' to be the most recent.
      service.update(entry('a', 1, DateTime(2026, 3, 1)));
      expect(service.entries.first.id, 'a');
    });

    test('update is a no-op for an unknown id', () async {
      final service = await PlayLogService.instance();
      service.logPlay(entry('a', 1, DateTime(2026, 1, 1)));
      service.update(entry('missing', 9, DateTime(2026, 1, 1)));
      expect(service.entries.length, 1);
      expect(service.entries.first.id, 'a');
    });

    test('notifies listeners on update', () async {
      final service = await PlayLogService.instance();
      service.logPlay(entry('a', 1, DateTime(2026, 1, 1)));
      var notified = false;
      service.addListener(() => notified = true);
      service.update(entry('a', 1, DateTime(2026, 2, 1)));
      expect(notified, isTrue);
    });

    test('notifies listeners on logPlay', () async {
      final service = await PlayLogService.instance();
      var notified = false;
      service.addListener(() => notified = true);
      service.logPlay(entry('a', 1, DateTime(2026, 1, 1)));
      expect(notified, isTrue);
    });

    test('notifies listeners on remove', () async {
      final service = await PlayLogService.instance();
      service.logPlay(entry('a', 1, DateTime(2026, 1, 1)));
      var notified = false;
      service.addListener(() => notified = true);
      service.remove('a');
      expect(notified, isTrue);
    });
  });

  group('persistence', () {
    test('saves entries to SharedPreferences', () async {
      final service = await PlayLogService.instance();
      service.logPlay(entry('a', 1, DateTime(2026, 1, 1), name: 'Catan'));

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('play_log');
      expect(raw, isNotNull);
      expect(raw, contains('Catan'));
    });

    test('loads persisted entries on init', () async {
      final saved = entry('a', 1, DateTime(2026, 1, 1), name: 'Catan');
      SharedPreferences.setMockInitialValues({
        'play_log': '[${_json(saved)}]',
      });

      final service = await PlayLogService.instance();
      expect(service.entries.length, 1);
      expect(service.entries.first.name, 'Catan');
    });
  });
}

String _json(PlayLogEntry e) {
  final t = e.playedAt.millisecondsSinceEpoch;
  return '{"i":"${e.id}","g":${e.gameId},"n":"${e.name}","d":$t}';
}
