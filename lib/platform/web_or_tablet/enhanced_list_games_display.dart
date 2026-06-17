import 'package:flutter/material.dart';
import 'package:how_many_mobile_meeple/components/app_default_padding.dart';
import 'package:how_many_mobile_meeple/platform/router.dart' as r;
import '../../app_page.dart';
import '../../app_common.dart';
import 'package:how_many_mobile_meeple/components/heading_text.dart';
import '../../how_many_meeple_app_bar.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import '../../model/game.dart';
import '../../model/games.dart';
import '../../network_content_widget.dart';
import 'package:how_many_mobile_meeple/components/platform_independent_image.dart';
import 'package:how_many_mobile_meeple/components/rating_badge.dart';

class EnhancedListGamesDisplayPage extends NetworkWidget with AppPage {
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
    var heading = [
      TableRow(children: [
        const TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: SizedBox(width: 48),
        ),
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: AppDefaultPadding(
            child: TextButton(
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                onPressed: () {
                  model.toggleSortDirection();
                  model.sortGameField = SortableGameField.name;
                  model.refreshState();
                },
                child: Container(
                    alignment: Alignment.bottomLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HeadingText("Name", context),
                        if (model.sortGameField == SortableGameField.name)
                          Icon(
                            model.sortDirection == SortOrder.Asc
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            size: 12,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                      ],
                    ))),
          ),
        ),
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: AppDefaultPadding(
            child: TextButton(
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                onPressed: () {
                  model.toggleSortDirection();
                  model.sortGameField = SortableGameField.maxPlaytime;
                  model.refreshState();
                },
                child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Icon(Icons.timer,
                      size: 18, color: Theme.of(context).colorScheme.secondary),
                  if (model.sortGameField == SortableGameField.maxPlaytime)
                    Icon(
                      model.sortDirection == SortOrder.Asc
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      size: 12,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                ])),
          ),
        ),
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: AppDefaultPadding(
            child: TextButton(
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                onPressed: () {
                  model.toggleSortDirection();
                  model.sortGameField = SortableGameField.weight;
                  model.refreshState();
                },
                child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Icon(Icons.fitness_center,
                      size: 18, color: Theme.of(context).colorScheme.secondary),
                  if (model.sortGameField == SortableGameField.weight)
                    Icon(
                      model.sortDirection == SortOrder.Asc
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      size: 12,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                ])),
          ),
        ),
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: AppDefaultPadding(
            child: TextButton(
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                onPressed: () {
                  model.toggleSortDirection();
                  model.sortGameField = SortableGameField.rating;
                  model.refreshState();
                },
                child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Icon(Icons.star,
                      size: 18, color: Theme.of(context).colorScheme.secondary),
                  if (model.sortGameField == SortableGameField.rating)
                    Icon(
                      model.sortDirection == SortOrder.Asc
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      size: 12,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                ])),
          ),
        ),
      ])
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Table(
        defaultColumnWidth: const FixedColumnWidth(60),
        columnWidths: const {
          0: FixedColumnWidth(56),
          1: FlexColumnWidth(4.0),
          2: MinColumnWidth(FlexColumnWidth(1.0), FixedColumnWidth(80)),
          3: FlexColumnWidth(1.0),
          4: FixedColumnWidth(60),
        },
        children: heading +
            (cachedGames.games
                .getGamesBy(
                    field: model.sortGameField, order: model.sortDirection)
                .asMap()
                .entries
                .map(
                  (entry) => _buildRow(context, entry.value, entry.key),
                )).toList(),
      ),
    );
  }

  TableRow _buildRow(BuildContext context, Game game, int index) {
    final isEven = index % 2 == 0;
    return TableRow(
        decoration: BoxDecoration(
          color: isEven
              ? Colors.transparent
              : Theme.of(context).colorScheme.primary.withAlpha(8),
          border:
              Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        children: [
          TableCell(
            verticalAlignment: TableCellVerticalAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: ClipRRect(
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
                              size: 22,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer),
                        ),
                ),
              ),
            ),
          ),
          TableCell(
              verticalAlignment: TableCellVerticalAlignment.middle,
              child: AppDefaultPadding(
                child: Container(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(game.name,
                            style: const TextStyle(
                              decoration: TextDecoration.underline,
                            )),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.people,
                                size: 12,
                                color: Theme.of(context).colorScheme.secondary),
                            const SizedBox(width: 3),
                            Text(
                              game.minPlayers == game.maxPlayers
                                  ? '${game.minPlayers} players'
                                  : '${game.minPlayers}-${game.maxPlayers} players',
                              style: TextStyle(
                                  fontSize: 11,
                                  color:
                                      Theme.of(context).colorScheme.secondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                    onTap: () => Navigator.of(context).pushNamed(
                        '${r.Router.gameDetailRoute}/${game.name.replaceAll(' ', '+')}/${game.id}'),
                  ),
                ),
              )),
          TableCell(
            verticalAlignment: TableCellVerticalAlignment.middle,
            child: AppDefaultPadding(
              child: Container(
                alignment: Alignment.centerRight,
                child: Text(AppCommon.minutesToTime(game.maxPlaytime)),
              ),
            ),
          ),
          TableCell(
            verticalAlignment: TableCellVerticalAlignment.middle,
            child: AppDefaultPadding(
              child: Container(
                alignment: Alignment.centerRight,
                child: Text(game.averageWeight.toStringAsFixed(2)),
              ),
            ),
          ),
          TableCell(
            verticalAlignment: TableCellVerticalAlignment.middle,
            child: Center(
              child: MiniRatingBadge(rating: game.averageRating, size: 38),
            ),
          ),
        ]);
  }
}
