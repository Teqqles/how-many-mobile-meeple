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
  });
}
