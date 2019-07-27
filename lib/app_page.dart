import 'dart:typed_data';

import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:flutter/material.dart';
import 'package:mime_type/mime_type.dart';
import 'package:http/http.dart' as http;
import 'package:scoped_model/scoped_model.dart';
import 'drawer_bgg_filter.dart';
import 'model/game.dart';
import 'model/model.dart';
import 'model/settings.dart';
import 'random_game_display.dart';
import 'app_default_padding.dart';
import 'list_games_display.dart';
import 'package:path/path.dart';

abstract class AppPage {
  static const String randomGameLabel = "Random Game";
  static Image randomGameButtonIcon = Image.asset('lib/images/dice.png');
  static const String randomGameHeroTag = "random-game";
  static const String listHeroTag = "list-games";

  final double _imageButtonSize = 42;

  List<Widget> drawerFilters(BuildContext context, AppModel model) => [
        DrawerBggFilter(
            "Recommended Player Count Filter",
            model.settings
                .setting(Settings.filterUsingUserRecommendations.name),
            model,
            context),
        DrawerBggFilter(
            "Include Expansions in Filter",
            model.settings.setting(Settings.filterIncludesExpansions.name),
            model,
            context),
        DrawerBggFilter(
            "Show All Mechanics",
            model.settings.setting(Settings.filterUseAllMechanics.name),
            model,
            context)
      ];

  void loadPage(BuildContext context, MaterialPageRoute<dynamic> page) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pushReplacement(
        page,
      );
    } else {
      Navigator.of(context).push(
        page,
      );
    }
  }

  Widget iconButtonGroup(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Container(
            decoration: new BoxDecoration(
              color: Theme.of(context).accentColor,
              borderRadius: new BorderRadius.circular(40.0),
            ),
            child: Padding(
              padding: EdgeInsets.only(left: 5, right: 5, top: 2, bottom: 2),
              child: IconButton(
                  color: Theme.of(context).selectedRowColor,
                  icon: Icon(
                    Icons.format_list_numbered,
                    size: 36,
                  ),
                  onPressed: () {
                    var listGamesPage = materialisePage(ListGamesDisplayPage());
                    loadPage(context, listGamesPage);
                  }),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8),
            child: MaterialButton(
              onPressed: () {
                var randomGamePage = materialisePage(RandomGameDisplayPage());
                loadPage(context, randomGamePage);
              },
              child: Container(
                decoration: new BoxDecoration(
                  color: Theme.of(context).accentColor,
                  borderRadius: new BorderRadius.circular(40.0),
                ),
                child: Padding(
                  padding: EdgeInsets.only(left: 18, right: 12, top: 5, bottom: 5),
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                        height: _imageButtonSize,
                        width: _imageButtonSize,
                        child: randomGameButtonIcon,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 8, right: 8),
                        child: Text(
                          randomGameLabel,
                          style: TextStyle(
                              color: Theme.of(context).selectedRowColor,
                              fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );

  RaisedButton shareButton(BuildContext context, Game game) {
    return RaisedButton(
        color: Theme.of(context).accentColor,
        child: Icon(
          Icons.share,
          color: Theme.of(context).selectedRowColor,
        ),
        onPressed: () async {
          var response = await http.get(game.imageUrl);
          var mimeType = mime(basename(game.imageUrl));
          Uint8List bytes = response.bodyBytes;
          await Share.file(
              "${game.name}", basename(game.imageUrl), bytes, mimeType,
              text:
                  "We'll next be playing this randomly selected game... ${game.name}");
        },
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)));
  }

  MaterialPageRoute materialisePage(StatelessWidget page) =>
      MaterialPageRoute(builder: (context) => page);

  Widget pageDrawer(BuildContext context) => Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            Container(
              height: 80.0,
              child: DrawerHeader(
                padding: EdgeInsets.only(left: 8),
                margin: EdgeInsets.zero,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    BackButton(color: Theme.of(context).selectedRowColor),
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Text(
                        'Advanced Options',
                        style: TextStyle(
                            color: Theme.of(context).selectedRowColor),
                      ),
                    )
                  ],
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).accentColor,
                ),
              ),
            ),
            ScopedModelDescendant<AppModel>(
              builder: (context, child, model) =>
                  Column(children: drawerFilters(context, model)),
            ),
          ],
        ),
      );
}
