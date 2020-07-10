import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sprintf/sprintf.dart';
import 'package:how_many_mobile_meeple/components/app_default_padding.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app_page.dart';
import '../../app_common.dart';
import 'package:how_many_mobile_meeple/components/heading_text.dart';
import '../../how_many_meeple_app_bar.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import '../../model/game.dart';
import '../../network_content_widget.dart';

class BasicListGamesDisplayPage extends NetworkWidget with AppPage {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: HowManyMeepleAppBar(AppCommon.listGamesPageTitle, context: context),
        persistentFooterButtons: [iconButtonGroup(context)],
        body: Container(child: loadNetworkContent(displayGame)));
  }

  Widget displayGame(
      BuildContext context, AppModel model) {
    var cachedGames = model.bggCache;
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
                                      child: InkWell(
                                        child: Text(
                                            game.name,
                                        style: TextStyle(
                                          decoration: TextDecoration.underline,
                                        )),
                                    onTap: () => launch("https://www.boardgamegeek.com/boardgame/${game.id}")
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
                                    sprintf("%0.2f", [game.averageWeight ?? 0.00]),
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
