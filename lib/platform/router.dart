import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:how_many_mobile_meeple/favourites/favourites_service.dart';
import 'package:how_many_mobile_meeple/favourites/ignored_games_service.dart';
import 'package:how_many_mobile_meeple/model/game_night.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/platform/pages.dart';
import 'package:how_many_mobile_meeple/platform/web/url_fragment_encoder.dart';

import 'package:how_many_mobile_meeple/about_page.dart' deferred as about;
import 'package:how_many_mobile_meeple/collection_insights/collection_insights_page.dart'
    deferred as collection_insights;
import 'package:how_many_mobile_meeple/favourites/game_list_page.dart'
    deferred as game_list;
import 'package:how_many_mobile_meeple/help/help_page.dart' deferred as help;
import 'package:how_many_mobile_meeple/platform/common/game_detail_page.dart'
    deferred as game_detail;
import 'package:how_many_mobile_meeple/play_log/play_log_page.dart'
    deferred as play_log;
import 'package:how_many_mobile_meeple/settings_summary_page.dart'
    deferred as settings_page;
import 'package:how_many_mobile_meeple/shelf_of_shame/shelf_of_shame_page.dart'
    deferred as shelf_of_shame;

class Router {
  static const String homeRoute = '/';
  static const String listRoute = '/list';
  static const String randomRoute = '/random';
  static const String settingsRoute = '/settings';
  static const String gameDetailRoute = '/game';
  static const String favouritesRoute = '/favourites';
  static const String ignoredRoute = '/ignored';
  static const String playLogRoute = '/play-log';
  static const String aboutRoute = '/about';
  static const String helpRoute = '/help';
  static const String shelfOfShameRoute = '/shelf-of-shame';
  static const String insightsRoute = '/insights';

  /// Path prefix for a shared Game Night link, e.g. `/gameNight/teqqles`. The
  /// prefix - not a query flag - is what puts the recipient in Game Night mode.
  static const String gameNightRoute = '/gameNight';

  /// Bare routes that carry no encoded model. [UrlFragmentExtractor] uses this
  /// to tell a plain navigation target (`/list`) from a model-bearing deep link
  /// (`/list/<collection>?<settings>`).
  static List<String> routeList = [
    randomRoute,
    listRoute,
    shelfOfShameRoute,
    insightsRoute,
    settingsRoute,
    homeRoute,
  ];

  /// The app's single [GoRouter]. Built once so its state (and the browser
  /// history it drives) survives widget rebuilds. Using the Router API gives us
  /// Flutter's [MultiEntryBrowserHistory], which maps browser back/forward to
  /// real Navigator pops - unlike the Navigator 1.0 API's single-entry history,
  /// which cancelled every popstate with `history.go(-1)` and bounced a
  /// re-visited tab off the app entirely.
  static final GoRouter router = GoRouter(
    routes: _routes(),
    // Any unmatched path falls back to the home page; the model still reads the
    // URL, so a malformed model link degrades to the home screen rather than an
    // error page.
    errorBuilder: (context, state) => Pages.platformPages().homePage(),
  );

  // Each model-bearing route (`/`, `/gameNight`, `/list`, `/random`) is
  // registered twice: bare, and with a `:payload` segment for the encoded
  // collection. Page widgets never read the payload - [AppModel] loads it from
  // the URL - so both variants build the same page. Keying pages by the full
  // location means re-visiting a different shared link remounts the page, which
  // re-runs its once-per-mount URL restore.
  static List<RouteBase> _routes() {
    final pages = Pages.platformPages();
    return [
      GoRoute(
        path: homeRoute,
        pageBuilder: (_, state) => _page(state, pages.homePage()),
      ),
      GoRoute(
        path: gameNightRoute,
        pageBuilder: (_, state) => _page(state, pages.homePage()),
      ),
      GoRoute(
        path: '$gameNightRoute/:payload',
        pageBuilder: (_, state) => _page(state, pages.homePage()),
      ),
      GoRoute(
        path: listRoute,
        pageBuilder: (_, state) =>
            _page(state, _deferred(pages.listGamesLoader, pages.listGamesPage)),
      ),
      GoRoute(
        path: '$listRoute/:payload',
        pageBuilder: (_, state) =>
            _page(state, _deferred(pages.listGamesLoader, pages.listGamesPage)),
      ),
      GoRoute(
        path: randomRoute,
        pageBuilder: (_, state) => _page(
          state,
          _deferred(pages.randomGameLoader, pages.randomGamePage),
        ),
      ),
      GoRoute(
        path: '$randomRoute/:payload',
        pageBuilder: (_, state) => _page(
          state,
          _deferred(pages.randomGameLoader, pages.randomGamePage),
        ),
      ),
      GoRoute(
        path: settingsRoute,
        pageBuilder: (_, state) => _page(
          state,
          _deferred(
            settings_page.loadLibrary,
            () => settings_page.SettingsSummaryPage(),
          ),
        ),
      ),
      GoRoute(
        path: favouritesRoute,
        pageBuilder: (_, state) => _page(
          state,
          _deferred(
            game_list.loadLibrary,
            () => game_list.GameListPage(
              title: 'Favourites',
              emptyIcon: Icons.favorite_border,
              emptyTitle: 'No favourites yet',
              emptyDescription: 'Swipe right on a game in the list or tap the heart on a game page to add favourites.',
              serviceFactory: FavouritesService.instance,
            ),
          ),
        ),
      ),
      GoRoute(
        path: ignoredRoute,
        pageBuilder: (_, state) => _page(
          state,
          _deferred(
            game_list.loadLibrary,
            () => game_list.GameListPage(
              title: 'Ignored Games',
              emptyIcon: Icons.visibility_off_outlined,
              emptyTitle: 'No ignored games',
              emptyDescription: 'Swipe left on a game in the list to hide it from future results.',
              serviceFactory: IgnoredGamesService.instance,
            ),
          ),
        ),
      ),
      GoRoute(
        path: playLogRoute,
        pageBuilder: (_, state) => _page(
          state,
          _deferred(play_log.loadLibrary, () => play_log.PlayLogPage()),
        ),
      ),
      GoRoute(
        path: insightsRoute,
        pageBuilder: (_, state) => _page(
          state,
          _deferred(
            collection_insights.loadLibrary,
            () => collection_insights.CollectionInsightsPage(),
          ),
        ),
      ),
      GoRoute(
        path: aboutRoute,
        pageBuilder: (_, state) =>
            _page(state, _deferred(about.loadLibrary, () => about.AboutPage())),
      ),
      GoRoute(
        path: helpRoute,
        pageBuilder: (_, state) => _helpPage(state, null),
      ),
      GoRoute(
        path: '$helpRoute/:section',
        pageBuilder: (_, state) =>
            _helpPage(state, state.pathParameters['section']),
      ),
      GoRoute(
        path: shelfOfShameRoute,
        pageBuilder: (_, state) => _shelfPage(state, null),
      ),
      GoRoute(
        path: '$shelfOfShameRoute/:user',
        pageBuilder: (_, state) => _shelfPage(
          state,
          Uri.decodeComponent(state.pathParameters['user']!),
        ),
      ),
      // A game detail link carries the game id in its last segment. It comes in
      // two shapes: `/game/<id>` and `/game/<name>/<id>`; the name segment is
      // decorative (readable/shareable), so both resolve on the id.
      GoRoute(
        path: '$gameDetailRoute/:id',
        pageBuilder: (_, state) =>
            _gameDetailPage(state, state.pathParameters['id']),
      ),
      GoRoute(
        path: '$gameDetailRoute/:name/:id',
        pageBuilder: (_, state) =>
            _gameDetailPage(state, state.pathParameters['id']),
      ),
    ];
  }

  static Page<dynamic> _page(GoRouterState state, Widget child) =>
      MaterialPage(key: ValueKey(state.uri.toString()), child: child);

  static Page<dynamic> _helpPage(GoRouterState state, String? section) => _page(
    state,
    _deferred(help.loadLibrary, () => help.HelpPage(initialSectionId: section)),
  );

  static Page<dynamic> _shelfPage(GoRouterState state, String? username) =>
      _page(
        state,
        _deferred(
          shelf_of_shame.loadLibrary,
          () => shelf_of_shame.ShelfOfShamePage(username: username),
        ),
      );

  static Page<dynamic> _gameDetailPage(GoRouterState state, String? idStr) {
    final gameId = int.tryParse(idStr ?? '');
    if (gameId == null) {
      return _page(state, Pages.platformPages().homePage());
    }
    return _page(
      state,
      _deferred(
        game_detail.loadLibrary,
        () => game_detail.GameDetailPage(gameId: gameId),
      ),
    );
  }

  /// Encodes the current model (collection + settings) onto [name] as a
  /// clean-path location string, e.g. `/list/teqqles?maxPlayers=4`, for
  /// imperative navigation (`context.pushReplacement(location)`).
  static String encodeLocation(String name, AppModel model) {
    return UrlFragmentEncoder.encode(
      name,
      items: model.items,
      settings: model.settings,
    );
  }

  /// A full shareable URL for the current Game Night lineup, e.g.
  /// `https://host/gameNight/teqqles?gameNightLineup=...`. The `/gameNight` path
  /// prefix puts the recipient in Game Night mode, with the shared collection
  /// loaded and the games pinned (see GameNightView) - no `gameNightMode` flag
  /// needed.
  static String gameNightPermalink(AppModel model, GameNightLineup lineup) {
    final location = UrlFragmentEncoder.encode(
      gameNightRoute,
      items: model.items,
      settings: model.gameNightPermalinkSettings(lineup),
    );
    // location is a leading-slash path (+ query); join it to the current
    // origin. Building the string directly avoids Uri re-encoding the already
    // encoded settings query.
    return '${originOf(Uri.base)}$location';
  }

  /// The scheme+authority to prefix a permalink with. On the web [Uri.base] is
  /// http(s) and [Uri.origin] applies; off the web (e.g. VM tests) [Uri.base]
  /// is a `file:` URI and `.origin` throws, so fall back to scheme+authority.
  static String originOf(Uri base) {
    if (base.isScheme('http') || base.isScheme('https')) return base.origin;
    return '${base.scheme}://${base.authority}';
  }
}

Widget _deferred(
  Future<void> Function() loadLibrary,
  Widget Function() builder,
) {
  return _DeferredPage(loadLibrary: loadLibrary, builder: builder);
}

/// Loads a deferred library, then shows the page it gates. The load future is
/// memoized so ancestor rebuilds reuse it rather than remounting the page.
class _DeferredPage extends StatefulWidget {
  final Future<void> Function() loadLibrary;
  final Widget Function() builder;

  const _DeferredPage({required this.loadLibrary, required this.builder});

  @override
  State<_DeferredPage> createState() => _DeferredPageState();
}

class _DeferredPageState extends State<_DeferredPage> {
  late final Future<void> _future = widget.loadLibrary();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return const Scaffold(
              body: Center(child: Text('Failed to load page')),
            );
          }
          return widget.builder();
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
