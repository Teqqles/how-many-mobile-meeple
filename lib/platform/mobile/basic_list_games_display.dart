import 'package:flutter/material.dart';
import 'package:how_many_mobile_meeple/platform/router.dart' as r;
import '../../app_page.dart';
import '../../app_common.dart';
import '../../how_many_meeple_app_bar.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import '../../model/game.dart';
import '../../model/games.dart';
import '../../network_content_widget.dart';
import 'package:how_many_mobile_meeple/components/platform_independent_image.dart';
import 'package:how_many_mobile_meeple/components/rating_badge.dart';

const _detailFontSize = 12.0;

class BasicListGamesDisplayPage extends NetworkWidget with AppPage {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar:
            HowManyMeepleAppBar(AppCommon.listGamesPageTitle, context: context),
        persistentFooterButtons: [iconButtonGroup(context)],
        body: Container(child: loadNetworkContent(displayGame)));
  }

  Widget displayGame(BuildContext context, AppModel model) {
    var cachedGames = model.bggCache;
    var games = cachedGames.games
        .getGamesBy(field: model.sortGameField, order: model.sortDirection);

    return Column(
      children: [
        _SortBar(model: model),
        Expanded(
          child: ListView.builder(
            itemCount: games.length,
            itemBuilder: (context, index) {
              final game = games[index];
              final isEven = index % 2 == 0;
              return _GameListTile(game: game, isEven: isEven);
            },
          ),
        ),
      ],
    );
  }
}

class _SortBar extends StatelessWidget {
  final AppModel model;

  const _SortBar({required this.model});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Text('Sort: ',
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.secondary)),
          _sortChip(context, 'Name', SortableGameField.name),
          _sortChip(context, 'Time', SortableGameField.maxPlaytime),
          _sortChip(context, 'Weight', SortableGameField.weight),
          _sortChip(context, 'Rating', SortableGameField.rating),
        ],
      ),
    );
  }

  Widget _sortChip(
      BuildContext context, String label, SortableGameField field) {
    final isActive = model.sortGameField == field;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          model.toggleSortDirection();
          model.sortGameField = field;
          model.refreshState();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isActive
                ? Theme.of(context).colorScheme.primary.withAlpha(30)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isActive
                ? '$label ${model.sortDirection == SortOrder.Asc ? '↑' : '↓'}'
                : label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _GameListTile extends StatelessWidget {
  final Game game;
  final bool isEven;

  const _GameListTile({required this.game, required this.isEven});

  @override
  Widget build(BuildContext context) {
    final detailColor = Theme.of(context).colorScheme.secondary;
    return InkWell(
      onTap: () => Navigator.of(context).pushNamed(
          '${r.Router.gameDetailRoute}/${game.name.replaceAll(' ', '+')}/${game.id}'),
      child: Container(
        color: isEven
            ? Colors.transparent
            : Theme.of(context).colorScheme.primary.withAlpha(12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: 44,
                height: 44,
                child: game.thumbnail != null
                    ? PlatformIndependentImage(
                        imageUrl: game.thumbnail!,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        child: Icon(Icons.casino,
                            size: 20,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer),
                      ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    game.name,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.people, size: 14, color: detailColor),
                      const SizedBox(width: 3),
                      Text(
                        game.minPlayers == game.maxPlayers
                            ? '${game.minPlayers}'
                            : '${game.minPlayers}-${game.maxPlayers}',
                        style: TextStyle(
                            fontSize: _detailFontSize, color: detailColor),
                      ),
                      const SizedBox(width: 10),
                      Icon(Icons.timer, size: 14, color: detailColor),
                      const SizedBox(width: 3),
                      Text(
                        AppCommon.minutesToTime(game.maxPlaytime),
                        style: TextStyle(
                            fontSize: _detailFontSize, color: detailColor),
                      ),
                      const SizedBox(width: 10),
                      Icon(Icons.fitness_center, size: 14, color: detailColor),
                      const SizedBox(width: 3),
                      Text(
                        '${game.averageWeight.toStringAsFixed(1)}/5',
                        style: TextStyle(
                            fontSize: _detailFontSize, color: detailColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            MiniRatingBadge(rating: game.averageRating),
          ],
        ),
      ),
    );
  }
}
