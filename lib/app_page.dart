import 'dart:typed_data';

import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:flutter/material.dart';
import 'package:how_many_mobile_meeple/platform/router.dart';
import 'package:mime_type/mime_type.dart';
import 'package:http/http.dart' as http;
import 'package:scoped_model/scoped_model.dart';
import 'package:how_many_mobile_meeple/components/drawer_bgg_filter.dart';
import 'app_common.dart';
import 'components/component_factory.dart';
import 'model/game.dart';
import 'model/model.dart';
import 'model/settings.dart';
import 'package:path/path.dart';

abstract class AppPage {
  static const String randomGameLabel = "Random Game";
  static Image randomGameButtonIcon = Image.asset('lib/images/dice.png');
  static const String randomGameHeroTag = "random-game";
  static const String listHeroTag = "list-games";

  final double _imageButtonSize = 42;

  Container drawerHeader(BuildContext context) => Container(
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
                  style: TextStyle(color: Theme.of(context).selectedRowColor),
                ),
              )
            ],
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).accentColor,
          ),
        ),
      );

  List<Widget> staticFilters(AppModel model, BuildContext context) => [
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
            context),
      ];

  Future<List<Widget>> drawerFilters(
      BuildContext context, AppModel model) async {
    var drawerSettingsColumn =
        await ComponentFactory.getDrawerSettingsColumn(AppCommon.savedSettings);
    return <Widget>[drawerHeader(context)] +
        staticFilters(model, context) +
        await drawerSettingsColumn.drawerContent(context, model);
  }

  void loadPage(BuildContext context, RouteSettings pageSettings) {
    AppModel.of(context).pageRefreshed = true;
    Navigator.of(context).pushReplacementNamed(
      pageSettings.name,
      arguments: pageSettings.arguments
    );
  }

  void startPage(BuildContext context) {
    AppModel.of(context).refreshFromUrl();
  }

  Widget iconButtonGroup(BuildContext context) =>
    Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).accentColor,
            borderRadius: BorderRadius.circular(40.0),
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
                  var listPageSettings = Router.generateRouteSettings(Router.listRoute, AppModel.of(context));
                  loadPage(context, listPageSettings);
                }),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8, right: 8),
          child: MaterialButton(
            onPressed: () {
              var randomPageSettings = Router.generateRouteSettings(Router.randomRoute, AppModel.of(context));
              loadPage(context, randomPageSettings);
            },
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).accentColor,
                borderRadius: BorderRadius.circular(40.0),
              ),
              child: Padding(
                padding:
                EdgeInsets.only(left: 18, right: 12, top: 5, bottom: 5),
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
              text: AppCommon.randomGameMessage(game.name));
        },
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)));
  }

  Widget pageDrawer(BuildContext context) {
    var staticDataComponentLength = 5;
    return ScopedModelDescendant<AppModel>(
      builder: (context, child, model) => Drawer(
        child: FutureBuilder(
          future: drawerFilters(context, model),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (!snapshot.hasData ||
                snapshot.data.length == staticDataComponentLength)
              return ListView(
                  children: <Widget>[drawerHeader(context)] +
                      staticFilters(model, context),
                  padding: EdgeInsets.zero);
            return ListView.builder(
              itemCount: snapshot.data.length,
              padding: EdgeInsets.zero,
              itemBuilder: (context, index) => snapshot.data[index],
            );
          },
        ),
      ),
    );
  }
}
