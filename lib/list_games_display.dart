import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sprintf/sprintf.dart';

import 'app_default_padding.dart';
import 'app_page.dart';
import 'package:how_many_mobile_meeple/model/bgg_cache.dart';
import 'game_config.dart';
import 'heading_text.dart';
import 'how_many_meeple_app_bar.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
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
    var thumbnailSize = 30.0;
    var heading = [
      TableRow(children: [
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: AppDefaultPadding(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Icon(Icons.image,
                    size: thumbnailSize, color: Theme.of(context).accentColor),
              ],
            ),
          ),
        ),
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: AppDefaultPadding(
            child: Container(
                alignment: Alignment.bottomLeft,
                child: HeadingText("Name", context)),
          ),
        ),
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: AppDefaultPadding(
            child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [HeadingText("Rating", context)]),
          ),
        ),
      ])
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Table(
        defaultColumnWidth: FixedColumnWidth(60),
        columnWidths: {1: FlexColumnWidth(4.0), 2: FlexColumnWidth(1.0)},
        children: heading +
            (cachedGames.games.getGamesByRating().map(
                      (game) => TableRow(
                          decoration: BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(
                                      color: Theme.of(context).dividerColor))),
                          children: [
                            TableCell(
                              child: AppDefaultPadding(
                                child: Container(
                                  alignment: Alignment.centerLeft,
                                  child: CachedNetworkImage(
                                    imageUrl: game.imageUrl,
                                    imageBuilder: (context, provider) =>
                                        Container(
                                      height: thumbnailSize,
                                      width: thumbnailSize,
                                      decoration: BoxDecoration(
                                        image: DecorationImage(
                                            image: provider, fit: BoxFit.fill),
                                      ),
                                    ),
                                    placeholder: (context, url) =>
                                        SpinKitCircle(
                                            color:
                                                Theme.of(context).accentColor,
                                            size: thumbnailSize),
                                    errorWidget: (context, url, error) =>
                                        Icon(Icons.error),
                                  ),
                                ),
                              ),
                            ),
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
