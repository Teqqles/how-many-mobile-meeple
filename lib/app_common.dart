
abstract class AppCommon {
  static const int splashScreenDisplayTime = 3600;
  static const String optionsPageTitle = 'Game Options';
  static const String savedSettings = 'Saved Settings';
  static const String randomGamePageTitle = 'Random Game';
  static const String listGamesPageTitle = 'List of Games';
  static const int maxItemsFromBgg = 5;
  static const String boardGameGeekProxyUrl = "http://game-selector.sixfootsoftware.com:8080";
  static const String disclaimerText = "Powered by Board Game Geek";
  static String randomGameMessage(String gameName) => "We'll next be playing this randomly selected game... $gameName";
}