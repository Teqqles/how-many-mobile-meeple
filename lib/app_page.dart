import 'dart:typed_data';

import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:flutter/material.dart';
import 'package:mime_type/mime_type.dart';
import 'package:scoped_multi_example/random_game_display.dart';
import 'package:http/http.dart' as http;

import 'load_games.dart';
import 'package:path/path.dart';

import 'package:flutter/foundation.dart';

abstract class AppPage {
  static const String randomGameLabel = "Random Game";
  static Image randomGameButtonIcon = Image.asset('lib/images/dice.png');

  FloatingActionButton floatingRandomGameButton(BuildContext context) =>
      FloatingActionButton.extended(
        onPressed: () {
          var materialisedPage = materialisePage(RandomGameDisplayPage());
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pushReplacement(
              materialisedPage,
            );
          } else {
            Navigator.of(context).push(
              materialisedPage,
            );
          }
        },
        icon: SizedBox(
          height: 42,
          width: 42,
          child: randomGameButtonIcon,
        ),
        label: Text(randomGameLabel),
      );

  RaisedButton shareButton(BuildContext context, Game game) {
    return RaisedButton(
        color: Theme.of(context).accentColor,
        child: new Icon(
          Icons.share,
          color: Theme.of(context).selectedRowColor,
        ),
        onPressed: () async {
          var response = await http.get(game.imageUrl);
          var mimeType = mime(basename(game.imageUrl));
          debugPrint(extension(game.imageUrl));
          Uint8List bytes = response.bodyBytes;
          debugPrint(mimeType);
          await Share.file(
              "${game.name}",
              basename(game.imageUrl),
              bytes,
              mimeType,
          text: "We'll next be playing this randomly selected game... ${game.name}");
        },
        shape: new RoundedRectangleBorder(
            borderRadius: new BorderRadius.circular(30.0)));
  }

  MaterialPageRoute materialisePage(StatelessWidget page) =>
      MaterialPageRoute(builder: (context) => page);
}
