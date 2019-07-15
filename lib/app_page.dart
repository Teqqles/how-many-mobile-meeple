import 'package:flutter/material.dart';
import 'package:scoped_multi_example/random_game_display.dart';

abstract class AppPage {
  static const String randomGameLabel = "Random Game";
  static Image randomGameButtonIcon = Image.asset('lib/images/dice.png');

  FloatingActionButton floatingRandomGameButton(BuildContext context) {
    return FloatingActionButton.extended(
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
  }

  MaterialPageRoute materialisePage(StatelessWidget page) =>
      MaterialPageRoute(builder: (context) => page);
}
