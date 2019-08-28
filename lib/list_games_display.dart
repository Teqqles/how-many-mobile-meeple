import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sprintf/sprintf.dart';
import 'app_default_padding.dart';
import 'app_page.dart';
import 'package:how_many_mobile_meeple/model/bgg_cache.dart';
import 'game_config.dart';
import 'heading_text.dart';
import 'how_many_meeple_app_bar.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'model/game.dart';
import 'model/games.dart';
import 'network_content_widget.dart';

class ListGamesDisplayPage extends NetworkWidget with AppPage {
  static final String route = "List-games-page";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: HowManyMeepleAppBar(GameConfig.listGamesPageTitle),
        persistentFooterButtons: [iconButtonGroup(context)],
        body: Container(child: loadNetworkContent(displayGame)));
  }

  Widget displayGame(
      BuildContext context, AppModel model, BggCache cachedGames) {
    var model = AppModel.of(context);
    var heading = [
      TableRow(children: [
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: AppDefaultPadding(
            child: FlatButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  model.toggleSortDirection();
                  model.sortGameField = SortableGameField.name;
                  model.refreshState();
                },
                child: Container(
                    alignment: Alignment.bottomLeft,
                    child: HeadingText("Name", context))),
          ),
        ),
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: AppDefaultPadding(
            child: FlatButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  model.toggleSortDirection();
                  model.sortGameField = SortableGameField.weight;
                  model.refreshState();
                },
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [HeadingText("Weight", context)])),
          ),
        ),
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: AppDefaultPadding(
            child: FlatButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  model.toggleSortDirection();
                  model.sortGameField = SortableGameField.rating;
                  model.refreshState();
                },
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [HeadingText("Rating", context)])),
          ),
        ),
      ])
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Table(
        defaultColumnWidth: FixedColumnWidth(60),
        columnWidths: {
          0: FlexColumnWidth(4.0),
          1: FlexColumnWidth(1.0),
          2: FlexColumnWidth(1.0)
        },
        children: heading +
            (cachedGames.games
                    .getGamesBy(
                        field: model.sortGameField, order: model.sortDirection)
                    .map(
                      (game) => TableRow(
                          decoration: BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(
                                      color: Theme.of(context).dividerColor))),
                          children: [
                            TableCell(
                                verticalAlignment:
                                    TableCellVerticalAlignment.middle,
                                child: AppDefaultPadding(
                                  child: Container(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        game.name,
                                      )),
                                )),
                            TableCell(
                              verticalAlignment:
                                  TableCellVerticalAlignment.middle,
                              child: AppDefaultPadding(
                                child: Container(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    sprintf("%0.2f", [game.averageWeight]),
                                  ),
                                ),
                              ),
                            ),
                            TableCell(
                              verticalAlignment:
                                  TableCellVerticalAlignment.middle,
                              child: AppDefaultPadding(
                                child: Container(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    sprintf("%0.2f", [game.averageRating]),
                                  ),
                                ),
                              ),
                            )
                          ]),
                    ))
                .toList(),
      ),
    );
  }
}
