import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'app_default_padding.dart';
import 'app_page.dart';
import 'game_config.dart';
import 'how_many_meeple_app_bar.dart';
import 'load_games.dart';
import 'network_content_widget.dart';

class ListGamesDisplay extends NetworkWidget with AppPage {
  static final String route = "List-games-page";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: HowManyMeepleAppBar(GameConfig.listGamesPageTitle),
        floatingActionButton: lightweightFloatingGroup(context),
        body: Container(child: loadNetworkContent(displayGame)));
  }

  Widget displayGame(BuildContext context, Games games) {
    var thumbnailSize = 30.0;
    var heading = [
      TableRow(children: [
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: AppDefaultPadding(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Icon(Icons.image, size: thumbnailSize),
              ],
            ),
          ),
        ),
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: AppDefaultPadding(
            child: Container(
                alignment: Alignment.bottomLeft,
                decoration: BoxDecoration(border: Border.all()),
                child: Text("Name")),
          ),
        ),
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: AppDefaultPadding(
            child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [Text("Rating")]),
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
            (games.getGamesByRating().map((game) => TableRow(children: [
                      TableCell(
                        child: AppDefaultPadding(
                          child: Container(
                            alignment: Alignment.centerLeft,
                            child: CachedNetworkImage(
                              imageUrl: game.imageUrl,
                              imageBuilder: (context, provider) => Container(
                                height: thumbnailSize,
                                width: thumbnailSize,
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                      image: provider, fit: BoxFit.fill),
                                ),
                              ),
                              placeholder: (context, url) => SpinKitCircle(
                                  color: Theme.of(context).accentColor,
                                  size: thumbnailSize),
                              errorWidget: (context, url, error) =>
                                  new Icon(Icons.error),
                            ),
                          ),
                        ),
                      ),
                      TableCell(
                          verticalAlignment: TableCellVerticalAlignment.middle,
                          child: AppDefaultPadding(
                            child: Container(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  game.name,
                                )),
                          )),
                      TableCell(
                          verticalAlignment: TableCellVerticalAlignment.middle,
                          child: AppDefaultPadding(
                            child: Container(
                                alignment: Alignment.centerRight,
                                child: Text(game.averageRating.toString())),
                          ))
                    ])))
                .toList(),
      ),
    );
  }
}
