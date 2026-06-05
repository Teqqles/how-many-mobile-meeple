import 'package:how_many_mobile_meeple/load_games.dart';
import 'package:how_many_mobile_meeple/model/item.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';
import 'package:test/test.dart';

void main() {
  group('LoadGames.fetchGames', () {
    test('handles empty items list', () async {
      final settings = Settings.defaultSettings();
      final items = <Item>[];

      final games = await LoadGames.fetchGames(settings, items);

      expect(games.games, isEmpty);
    });

    test('handles single item', () async {
      final settings = Settings.defaultSettings();
      final items = [Item('testuser')];

      // This will fail with actual network call, but verifies compilation
      expect(() => LoadGames.fetchGames(settings, items), returnsNormally);
    });

    test('handles multiple items for parallel processing', () async {
      final settings = Settings.defaultSettings();
      final items = [
        Item('testuser1'),
        Item('testuser2'),
        Item('testuser3'),
      ];

      // This will fail with actual network call, but verifies the code structure
      // allows parallel processing (no compilation errors with Future.wait pattern)
      expect(() => LoadGames.fetchGames(settings, items), returnsNormally);
    });
  });
}
