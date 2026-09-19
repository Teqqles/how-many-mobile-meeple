import 'game.dart';
import 'item.dart';

/// Which source (collection or geeklist) each pool game came from, so Game
/// Night can show a slot's provenance. Built at fetch time; the merged pool
/// keys games by name and loses their origin.
///
/// A collection beats a geeklist; ties keep add order. Hotlists are ignored.
class GameSources {
  final Map<int, Item> _byGameId;

  const GameSources(this._byGameId);

  const GameSources.empty() : _byGameId = const {};

  /// The source a game came from, or null when no tracked source holds it.
  Item? sourceFor(int gameId) => _byGameId[gameId];

  /// Ranks collections ahead of geeklists (ties by add order), then the first
  /// source to claim a game id owns it. Hotlists are skipped.
  factory GameSources.fromSources(
    List<({Item item, List<Game> games})> sources,
  ) {
    final ranked =
        [
          for (var addOrder = 0; addOrder < sources.length; addOrder++)
            (addOrder: addOrder, source: sources[addOrder]),
        ]..sort((a, b) {
          final byType = _rank(a.source.item).compareTo(_rank(b.source.item));
          return byType != 0 ? byType : a.addOrder.compareTo(b.addOrder);
        });

    final byGameId = <int, Item>{};
    for (final entry in ranked) {
      final source = entry.source;
      if (source.item.itemType == ItemType.hotList) continue;
      for (final game in source.games) {
        byGameId.putIfAbsent(game.id, () => source.item);
      }
    }
    return GameSources(byGameId);
  }

  static int _rank(Item item) => item.itemType == ItemType.collection ? 0 : 1;
}
