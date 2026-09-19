import 'game.dart';
import 'item.dart';

/// Records which source (a collection or geeklist) each game in the pool came
/// from, so Game Night can show a slot's provenance. Built at fetch time, when
/// the per-source origin is still known - the merged pool keys games by name and
/// loses it.
///
/// When a game appears in more than one source, a collection is preferred over a
/// geeklist; within one type the source added first wins. Hotlist sources carry
/// no meaningful owner and are ignored.
class GameSources {
  final Map<int, Item> _byGameId;

  const GameSources(this._byGameId);

  const GameSources.empty() : _byGameId = const {};

  /// The source a game came from, or null when no tracked source holds it.
  Item? sourceFor(int gameId) => _byGameId[gameId];

  /// Builds the map from each source's games, in the order the sources were
  /// added. Collections are ranked ahead of geeklists; ties keep add order.
  /// The first source to claim a game id owns it (later duplicates are dropped),
  /// and hotlist sources are skipped.
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
