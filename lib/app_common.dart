abstract class AppCommon {
  static const String appTitle = 'How Many Meeple?';
  static const int splashScreenDisplayTime = 3600;
  static const double standardIconSize = 30.0;
  static const String optionsPageTitle = 'Game Options';
  static const String savedSettings = 'Saved Settings';
  static const String randomGamePageTitle = 'Random Game';
  static const String listGamesPageTitle = 'List of Games';
  static const String labelDifficulty = 'How Difficult?';
  static const String labelPlayers = 'Players?';
  static const String labelTime = 'Time?';
  static const String labelMechanics = 'Mechanics?';
  static const int maxItemsFromBgg = 5;
  static const String boardGameGeekProxyUrl =
      "http://game-selector.sixfootsoftware.com:8080";
  static const String disclaimerText = "Powered by Board Game Geek";

  static String randomGameMessage(String gameName) =>
      "We'll next be playing this randomly selected game... $gameName";
  static const String itemHintTextMessage = "bgg username/geeklist id";
  static const String maxItemsMessage = "max items entered";
}
