@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:how_many_mobile_meeple/model/game.dart';

Map<String, dynamic> _gameJson({Object? lastmodified = _absent}) => {
      'id': 174430,
      'name': 'Gloomhaven',
      'minplayers': 1,
      'maxplayers': 4,
      'maxplaytime': 120,
      'image': 'http://example.com/gloom.jpg',
      'thumbnail': 'http://example.com/gloom_t.jpg',
      'stats': {'average': 8.6, 'averageweight': 3.9},
      if (!identical(lastmodified, _absent)) 'lastmodified': lastmodified,
    };

const Object _absent = Object();

void main() {
  group('Game.fromJson lastModified', () {
    test('parses a YYYY-MM-DD string into a DateTime', () {
      final game = Game.fromJson(_gameJson(lastmodified: '2022-03-15'));

      expect(game.lastModified, DateTime(2022, 3, 15));
    });

    test('is null when the field is explicitly null', () {
      final game = Game.fromJson(_gameJson(lastmodified: null));

      expect(game.lastModified, isNull);
    });

    test('is null when the field is absent (whitelist omitted it)', () {
      final game = Game.fromJson(_gameJson());

      expect(game.lastModified, isNull);
    });

    test('is null when the field is a blank string', () {
      final game = Game.fromJson(_gameJson(lastmodified: ''));

      expect(game.lastModified, isNull);
    });

    test('is null for an unparseable date', () {
      final game = Game.fromJson(_gameJson(lastmodified: 'not-a-date'));

      expect(game.lastModified, isNull);
    });

    test('parses the other fields alongside lastModified', () {
      final game = Game.fromJson(_gameJson(lastmodified: '2022-03-15'));

      expect(game.id, 174430);
      expect(game.name, 'Gloomhaven');
      expect(game.averageRating, 8.6);
    });
  });
}
