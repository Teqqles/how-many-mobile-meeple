@Tags(['unit'])
library;

import 'package:test/test.dart';
import 'package:how_many_mobile_meeple/model/recommendation.dart';

void main() {
  group('Recommendation.fromJson', () {
    test('parses required fields', () {
      final rec = Recommendation.fromJson({
        'game_id': 42,
        'name': 'Wingspan',
        'similarity_score': 0.91,
      });

      expect(rec.gameId, 42);
      expect(rec.name, 'Wingspan');
      expect(rec.similarityScore, 0.91);
      expect(rec.game, isNull);
    });

    test('parses integer similarity score', () {
      final rec = Recommendation.fromJson({
        'game_id': 1,
        'name': 'Catan',
        'similarity_score': 1,
      });

      expect(rec.similarityScore, 1.0);
    });

    test('parses embedded game when present', () {
      final rec = Recommendation.fromJson({
        'game_id': 42,
        'name': 'Wingspan',
        'similarity_score': 0.85,
        'game': {
          'id': 42,
          'name': 'Wingspan',
          'maxplayers': 5,
          'minplayers': 1,
          'maxplaytime': 70,
          'image': 'http://example.com/img.jpg',
          'stats': {
            'average': 8.1,
            'averageweight': 2.4,
          },
        },
      });

      expect(rec.game, isNotNull);
      expect(rec.game!.name, 'Wingspan');
      expect(rec.game!.id, 42);
    });
  });
}
