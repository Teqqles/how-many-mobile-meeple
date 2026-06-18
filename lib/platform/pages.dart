import 'package:flutter/cupertino.dart';
import 'package:how_many_mobile_meeple/guided_flow_homepage.dart';
import 'package:how_many_mobile_meeple/platform/web_or_tablet/enhanced_list_games_display.dart';
import 'package:how_many_mobile_meeple/platform/web_or_tablet/web_random_game_display.dart';

abstract class Pages {
  Widget homePage();
  Widget randomGamePage();
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
  Widget randomGamePage() {
    return WebRandomGameDisplayPage();
  }

  @override
  Widget listGamesPage() {
    return EnhancedListGamesDisplayPage();
  }
}
