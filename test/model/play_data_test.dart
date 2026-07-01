@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:how_many_mobile_meeple/model/play_data.dart';

void main() {
  group('PlayData', () {
    test('fromJson parses complete play data', () {
      final json = {
        'game_id': 123,
        'game_name': 'Wingspan',
        'total_plays': 5,
      };

      final playData = PlayData.fromJson(json);

      expect(playData.gameId, 123);
      expect(playData.gameName, 'Wingspan');
      expect(playData.totalPlays, 5);
    });

    test('fromJson defaults totalPlays to 0 when missing', () {
      final json = {
        'game_id': 456,
        'game_name': 'Catan',
      };

      final playData = PlayData.fromJson(json);

      expect(playData.totalPlays, 0);
    });

    test('fromJson defaults totalPlays to 0 when null', () {
      final json = {
        'game_id': 789,
        'game_name': 'Azul',
        'total_plays': null,
      };

      final playData = PlayData.fromJson(json);

      expect(playData.totalPlays, 0);
    });

    test('equality is based on gameId', () {
      final play1 = PlayData(gameId: 1, gameName: 'Wingspan', totalPlays: 5);
      final play2 = PlayData(gameId: 1, gameName: 'Wingspan', totalPlays: 10);
      final play3 = PlayData(gameId: 2, gameName: 'Catan', totalPlays: 5);

      expect(play1, equals(play2));
      expect(play1, isNot(equals(play3)));
    });

    test('hashCode is consistent with equality', () {
      final play1 = PlayData(gameId: 1, gameName: 'Wingspan', totalPlays: 5);
      final play2 = PlayData(gameId: 1, gameName: 'Wingspan', totalPlays: 10);

      expect(play1.hashCode, equals(play2.hashCode));
    });

    test('toString returns descriptive string', () {
      final playData =
          PlayData(gameId: 123, gameName: 'Wingspan', totalPlays: 5);

      expect(playData.toString(), 'Wingspan (id: 123, plays: 5)');
    });

    test('fromJson parses individual plays with players', () {
      final json = {
        'game_id': 337765,
        'game_name': 'Brian Boru',
        'total_plays': 1,
        'plays': [
          {
            'play_id': 115665354,
            'date': '2026-06-29',
            'length': 90,
            'players': [
              {
                'username': 'Teqqles',
                'name': 'David Long',
                'score': null,
                'win': false
              },
              {'username': '', 'name': 'Thomas', 'score': 42, 'win': true},
            ],
          },
        ],
      };

      final playData = PlayData.fromJson(json);

      expect(playData.plays.length, 1);
      final play = playData.plays.single;
      expect(play.playId, 115665354);
      expect(play.date, DateTime(2026, 6, 29));
      expect(play.length, 90);
      expect(play.players.length, 2);
      expect(play.players[0].name, 'David Long');
      expect(play.players[0].win, isFalse);
      expect(play.players[1].name, 'Thomas');
      expect(play.players[1].score, 42);
      expect(play.players[1].win, isTrue);
    });

    test('fromJson defaults plays to empty when absent', () {
      final playData = PlayData.fromJson({
        'game_id': 1,
        'game_name': 'Aggregated only',
        'total_plays': 3,
      });
      expect(playData.plays, isEmpty);
    });

    test('BggPlayer falls back to username when name is blank', () {
      final player = BggPlayer.fromJson(
          {'username': 'DragonC', 'name': '', 'score': null, 'win': false});
      expect(player.name, 'DragonC');
    });

    test('BggPlay tolerates a missing date', () {
      final play = BggPlay.fromJson({'play_id': 1, 'date': '', 'players': []});
      expect(play.date, isNull);
    });

    test('BggPlayer keeps a numeric double score', () {
      final player = BggPlayer.fromJson(
          {'username': 'a', 'name': 'A', 'score': 50.5, 'win': false});
      expect(player.score, 51, reason: 'double score rounded, not dropped');
    });

    test('BggPlayer parses a string score', () {
      final player = BggPlayer.fromJson(
          {'username': 'a', 'name': 'A', 'score': '42', 'win': false});
      expect(player.score, 42);
    });

    test('BggPlayer leaves a null score null', () {
      final player = BggPlayer.fromJson(
          {'username': 'a', 'name': 'A', 'score': null, 'win': false});
      expect(player.score, isNull);
    });

    test('BggPlayer retains the username alongside the display name', () {
      final player = BggPlayer.fromJson(
          {'username': 'Teqqles', 'name': 'David Long', 'win': false});
      expect(player.name, 'David Long');
      expect(player.username, 'Teqqles');
    });
  });
}
