// coverage:ignore-file
import 'package:flutter/cupertino.dart';
import 'package:how_many_mobile_meeple/guided_flow_homepage.dart';
import 'package:how_many_mobile_meeple/platform/web_or_tablet/enhanced_list_games_display.dart'
    deferred as list_page;
import 'package:how_many_mobile_meeple/platform/web_or_tablet/web_random_game_display.dart'
    deferred as random_page;

abstract class Pages {
  Widget homePage();
  Future<void> Function() get randomGameLoader;
  Widget randomGamePage();
  Future<void> Function() get listGamesLoader;
  Widget listGamesPage();

  static Pages platformPages() {
    return WebPages();
  }

  static bool isLargeDevice() {
    final data = MediaQueryData.fromView(
        WidgetsBinding.instance.platformDispatcher.views.first);
    return data.size.shortestSide >= 600;
  }
}

class WebPages extends Pages {
  @override
  Widget homePage() {
    return GuidedFlowHomePage();
  }

  @override
  Future<void> Function() get randomGameLoader => random_page.loadLibrary;

  @override
  Widget randomGamePage() {
    return random_page.WebRandomGameDisplayPage();
  }

  @override
  Future<void> Function() get listGamesLoader => list_page.loadLibrary;

  @override
  Widget listGamesPage() {
    return list_page.EnhancedListGamesDisplayPage();
  }
}
