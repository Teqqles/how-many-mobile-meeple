@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_many_mobile_meeple/favourites/favourites_service.dart';
import 'package:how_many_mobile_meeple/favourites/game_list_page.dart';
import 'package:how_many_mobile_meeple/favourites/ignored_games_service.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/tour_tips/tour_tip_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _buildTestApp(Widget page) {
  return ChangeNotifierProvider<AppModel>.value(
    value: AppModel(),
    child: MaterialApp(home: page),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FavouritesService.resetForTesting();
    IgnoredGamesService.resetForTesting();
    TourTipService.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'tour_tips_disabled': true,
    });
  });

  group('All pages have an endDrawer', () {
    testWidgets('favourites page has endDrawer', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        GameListPage(
          title: 'Favourites',
          emptyIcon: Icons.favorite_border,
          emptyTitle: 'No favourites yet',
          emptyDescription: 'Swipe right on a game in the list.',
          serviceFactory: FavouritesService.instance,
        ),
      ));
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.endDrawer, isNotNull,
          reason: 'Favourites page must have an endDrawer');
    });

    testWidgets('ignored games page has endDrawer', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        GameListPage(
          title: 'Ignored Games',
          emptyIcon: Icons.visibility_off_outlined,
          emptyTitle: 'No ignored games',
          emptyDescription: 'Swipe left on a game in the list.',
          serviceFactory: IgnoredGamesService.instance,
        ),
      ));
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.endDrawer, isNotNull,
          reason: 'Ignored games page must have an endDrawer');
    });

    testWidgets('GameListPage always includes endDrawer', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        GameListPage(
          title: 'Test List',
          emptyIcon: Icons.star,
          emptyTitle: 'Empty',
          emptyDescription: 'No items',
          serviceFactory: FavouritesService.instance,
        ),
      ));
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.endDrawer, isNotNull,
          reason: 'GameListPage must have an endDrawer');
    });
  });
}
