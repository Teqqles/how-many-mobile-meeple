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

  Widget floatingActionButtonGroup(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          FloatingActionButton(
              heroTag: listHeroTag,
              child: Icon(
                Icons.format_list_numbered,
                size: 36,
              ),
              onPressed: () {
                var listGamesPage = materialisePage(ListGamesDisplay());
                loadPage(context, listGamesPage);
              }),
          AppDefaultPadding(
            child: FloatingActionButton.extended(
              heroTag: randomGameHeroTag,
              onPressed: () {
                var randomGamePage = materialisePage(RandomGameDisplayPage());
                loadPage(context, randomGamePage);
              },
              icon: SizedBox(
                height: _imageButtonSize,
                width: _imageButtonSize,
                child: randomGameButtonIcon,
              ),
              label: Text(randomGameLabel),
            ),
          ),
        ],
      );

  Widget lightweightFloatingGroup(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          AppDefaultPadding(
            child: FloatingActionButton(
                heroTag: listHeroTag,
                child: Icon(
                  Icons.format_list_numbered,
                  size: 36,
                ),
                onPressed: () {
                  var listGamesPage = materialisePage(ListGamesDisplay());
                  loadPage(context, listGamesPage);
                }),
          ),
          AppDefaultPadding(
            child: FloatingActionButton(
                heroTag: randomGameHeroTag,
                onPressed: () {
                  var randomGamePage = materialisePage(RandomGameDisplayPage());
                  loadPage(context, randomGamePage);
                },
                child: SizedBox(
                  height: _imageButtonSize,
                  width: _imageButtonSize,
                  child: randomGameButtonIcon,
                )),
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
