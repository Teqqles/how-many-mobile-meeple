
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:how_many_mobile_meeple/homepage.dart';
import 'package:how_many_mobile_meeple/platform/mobile/basic_list_games_display.dart';
import 'package:how_many_mobile_meeple/platform/mobile/mobile_random_game_display.dart';
import 'package:how_many_mobile_meeple/platform/web_or_tablet/enhanced_list_games_display.dart';
import 'package:how_many_mobile_meeple/platform/web_or_tablet/web_random_game_display.dart';

abstract class Pages {
  Widget homePage();
  Widget randomGamePage();
  Widget listGamesPage();

  static Pages platformPages() {
    return kIsWeb ? WebPages() : MobilePages();
  }

  static bool isLargeDevice() {
    final data = MediaQueryData.fromWindow(WidgetsBinding.instance.window);
    return data.size.shortestSide >= 600;
  }
}

class WebPages extends Pages {
  @override
  Widget homePage() {
    return HomePage();
  }

  @override
  Widget randomGamePage() {
    return WebRandomGameDisplayPage();
  }

  @override
  Widget listGamesPage() {
    if (Pages.isLargeDevice()) {
      return EnhancedListGamesDisplayPage();
    } else {
      return BasicListGamesDisplayPage();
    }
  }

}

class MobilePages extends Pages {
  @override
  Widget homePage() {
    return HomePage();
  }

  @override
  Widget randomGamePage() {
    return MobileRandomGameDisplayPage();
  }

  @override
  Widget listGamesPage() {
    if (Pages.isLargeDevice()) {
      return EnhancedListGamesDisplayPage();
    } else {
      return BasicListGamesDisplayPage();
    }
  }
}