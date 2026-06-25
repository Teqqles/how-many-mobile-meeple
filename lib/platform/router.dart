import 'package:flutter/material.dart';
import 'package:how_many_mobile_meeple/about_page.dart';
import 'package:how_many_mobile_meeple/favourites/favourites_service.dart';
import 'package:how_many_mobile_meeple/favourites/game_list_page.dart';
import 'package:how_many_mobile_meeple/favourites/ignored_games_service.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/platform/common/game_detail_page.dart';
import 'package:how_many_mobile_meeple/platform/pages.dart';
import 'package:how_many_mobile_meeple/platform/web/url_fragment_encoder.dart';
import 'package:how_many_mobile_meeple/settings_summary_page.dart';

class Router {
  static const String homeRoute = '/';
  static const String listRoute = '/list';
  static const String randomRoute = '/random';
  static const String settingsRoute = '/settings';
  static const String gameDetailRoute = '/game';
  static const String favouritesRoute = '/favourites';
  static const String ignoredRoute = '/ignored';
  static const String aboutRoute = '/about';

  static List<String> routeList = [
    randomRoute,
    listRoute,
    settingsRoute,
    homeRoute
  ];

  static Route<dynamic> generateRoute(RouteSettings settings) {
    var secondSlash = settings.name!.substring(1).indexOf("/");
    var path = secondSlash == -1
        ? settings.name!
        : settings.name!.substring(0, secondSlash + 1);

    if (path == Router.gameDetailRoute) {
      final segments =
          settings.name!.split('/').where((s) => s.isNotEmpty).toList();
      final idStr = segments.last;
      final gameId = int.tryParse(idStr);
      if (gameId != null) {
        return MaterialPageRoute(
            builder: (_) => GameDetailPage(gameId: gameId), settings: settings);
      }
    }

    switch (path) {
      case Router.homeRoute:
        return MaterialPageRoute(
            builder: (_) => Pages.platformPages().homePage(),
            settings: settings);
      case Router.listRoute:
        return MaterialPageRoute(
            builder: (_) => Pages.platformPages().listGamesPage(),
            settings: settings);
      case Router.randomRoute:
        return MaterialPageRoute(
            builder: (_) => Pages.platformPages().randomGamePage(),
            settings: settings);
      case Router.settingsRoute:
        return MaterialPageRoute(
            builder: (_) => SettingsSummaryPage(), settings: settings);
      case Router.favouritesRoute:
        return MaterialPageRoute(
            builder: (_) => GameListPage(
                  title: 'Favourites',
                  emptyIcon: Icons.favorite_border,
                  emptyTitle: 'No favourites yet',
                  emptyDescription:
                      'Swipe right on a game in the list or tap the heart on a game page to add favourites.',
                  serviceFactory: FavouritesService.instance,
                ),
            settings: settings);
      case Router.ignoredRoute:
        return MaterialPageRoute(
            builder: (_) => GameListPage(
                  title: 'Ignored Games',
                  emptyIcon: Icons.visibility_off_outlined,
                  emptyTitle: 'No ignored games',
                  emptyDescription:
                      'Swipe left on a game in the list to hide it from future results.',
                  serviceFactory: IgnoredGamesService.instance,
                ),
            settings: settings);
      case Router.aboutRoute:
        return MaterialPageRoute(
            builder: (_) => const AboutPage(), settings: settings);
      default:
        return MaterialPageRoute(
            builder: (_) => Pages.platformPages().homePage(),
            settings: settings);
    }
  }

  static RouteSettings generateRouteSettings(String name, AppModel model) {
    var items = model.items;
    var settings = model.settings;
    var encodedName =
        UrlFragmentEncoder.encode(name, items: items, settings: settings);
    return RouteSettings(name: encodedName);
  }
}
