import 'package:flutter/material.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/platform/pages.dart';
import 'package:how_many_mobile_meeple/platform/web/url_fragment_encoder.dart';
import 'package:how_many_mobile_meeple/settings_summary_page.dart';

class Router {
  static const String homeRoute = '/';
  static const String listRoute = '/list';
  static const String randomRoute = '/random';
  static const String settingsRoute = '/settings';

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
