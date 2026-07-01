@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:how_many_mobile_meeple/play_log/play_log_entry.dart';

void main() {
  group('PlayLogEntry serialization', () {
    test('round-trips through JSON', () {
      final entry = PlayLogEntry(
        id: 'x1',
        gameId: 42,
        name: 'Wingspan',
        thumbnail: 'http://img/thumb.png',
        playedAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
        players: [
          PlayerResult(name: 'Alice', won: true, score: 78),
          PlayerResult(name: 'Bob', score: 65),
        ],
      );

      final restored = PlayLogEntry.fromJson(entry.toJson());

      expect(restored.id, 'x1');
      expect(restored.gameId, 42);
      expect(restored.name, 'Wingspan');
      expect(restored.thumbnail, 'http://img/thumb.png');
      expect(restored.playedAt, entry.playedAt);
      expect(restored.players.length, 2);
      expect(restored.players[0].name, 'Alice');
      expect(restored.players[0].won, isTrue);
      expect(restored.players[0].score, 78);
      expect(restored.players[1].won, isFalse);
      expect(restored.players[1].score, 65);
    });

    test('uses compact keys and omits defaults', () {
      final entry = PlayLogEntry(
        id: 'x1',
        gameId: 42,
        name: 'Wingspan',
        playedAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
        players: [PlayerResult(name: 'Alice')],
      );

      final json = entry.toJson();

      expect(json.containsKey('i'), isTrue);
      expect(json.containsKey('g'), isTrue);
      expect(json.containsKey('t'), isFalse, reason: 'null thumbnail omitted');
      expect(json['d'], isA<int>(), reason: 'date stored as epoch millis');

      final playerJson = (json['p'] as List).first as Map;
      expect(playerJson.containsKey('w'), isFalse, reason: 'won=false omitted');
      expect(playerJson.containsKey('s'), isFalse, reason: 'no score omitted');
    });

    test('omits empty player list', () {
      final entry = PlayLogEntry(
        id: 'x1',
        gameId: 42,
        name: 'Wingspan',
        playedAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
      );
      expect(entry.toJson().containsKey('p'), isFalse);
    });

    test('reads legacy long-key format', () {
      final restored = PlayLogEntry.fromJson({
        'id': 'old1',
        'gameId': 7,
        'name': 'Catan',
        'thumbnail': null,
        'playedAt': '2024-01-15T10:00:00.000',
        'players': [
          {'name': 'Alice', 'won': true, 'score': 10},
        ],
      });

      expect(restored.id, 'old1');
      expect(restored.gameId, 7);
      expect(restored.name, 'Catan');
      expect(restored.playedAt, DateTime.parse('2024-01-15T10:00:00.000'));
      expect(restored.players.single.won, isTrue);
      expect(restored.players.single.score, 10);
    });
  });
}
