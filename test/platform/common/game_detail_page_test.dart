@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_inject/flutter_inject.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_many_mobile_meeple/model/game.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/model/recommendation.dart';
import 'package:how_many_mobile_meeple/platform/common/game_detail_page.dart';
import 'package:how_many_mobile_meeple/services/service_locator.dart';
import 'package:how_many_mobile_meeple/favourites/favourites_service.dart';
import 'package:how_many_mobile_meeple/favourites/ignored_games_service.dart';
import 'package:how_many_mobile_meeple/play_log/play_log_service.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _testGame = Game.fromJson(const {
  'id': 42,
  'name': 'Wingspan',
  'maxplayers': 5,
  'minplayers': 1,
  'maxplaytime': 70,
  'image': '',
  'stats': {
    'average': 8.1,
    'averageweight': 2.4,
  },
});

class _FakeGameDetailFetcher implements GameDetailFetcher {
  final Game? game;
  final Exception? error;
  int callCount = 0;

  _FakeGameDetailFetcher({this.game, this.error});

  @override
  Future<Game> fetchGame(int gameId) {
    callCount++;
    if (error != null) return Future.error(error!);
    return Future.value(game);
  }
}

class _FakeRecommendationsFetcher implements RecommendationsFetcher {
  @override
  Future<List<Recommendation>> fetchRecommendations({
    required List<int> gameIds,
    required Map<String, String> headers,
    int limit = 10,
    List<int> excludeIds = const [],
  }) =>
      Future.value([]);
}

class _FakeGameServices implements GameServices {
  final FavouritesService _favs;
  final IgnoredGamesService _ignored;
  final PlayLogService _playLog;

  _FakeGameServices(this._favs, this._ignored, this._playLog);

  @override
  Future<FavouritesService> favourites() => Future.value(_favs);
  @override
  Future<IgnoredGamesService> ignored() => Future.value(_ignored);
  @override
  Future<PlayLogService> playLog() => Future.value(_playLog);
}

Widget _buildTestApp(
  AppModel model, {
  required GameDetailFetcher fetcher,
  RecommendationsFetcher? recommendations,
  GameServices? services,
  int gameId = 42,
}) {
  return ChangeNotifierProvider<AppModel>.value(
    value: model,
    child: InjectAll(
      dependencies: [
        Dependency<GameDetailFetcher>((_) => fetcher),
        Dependency<RecommendationsFetcher>(
            (_) => recommendations ?? _FakeRecommendationsFetcher()),
        if (services != null) Dependency<GameServices>((_) => services),
      ],
      builder: (_) => MaterialApp(
        home: GameDetailPage(gameId: gameId),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppModel model;
  late FavouritesService favs;
  late IgnoredGamesService ignored;
  late PlayLogService playLog;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FavouritesService.resetForTesting();
    IgnoredGamesService.resetForTesting();
    PlayLogService.resetForTesting();
    favs = await FavouritesService.instance();
    ignored = await IgnoredGamesService.instance();
    playLog = await PlayLogService.instance();
    model = AppModel();
  });

  tearDown(() {
    FavouritesService.resetForTesting();
    IgnoredGamesService.resetForTesting();
    PlayLogService.resetForTesting();
  });

  group('GameDetailPage', () {
    testWidgets('shows Game Details title in app bar', (tester) async {
      final fetcher = _FakeGameDetailFetcher(game: _testGame);
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(_buildTestApp(
          model,
          fetcher: fetcher,
          services: _FakeGameServices(favs, ignored, playLog),
        ));
        await tester.pump();
      });

      expect(find.text('Game Details'), findsOneWidget);
    });

    testWidgets('shows loading indicator when fetch is pending',
        (tester) async {
      final fetcher = _FakeGameDetailFetcher(game: _testGame);
      await tester.pumpWidget(_buildTestApp(model, fetcher: fetcher));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders game name after data arrives', (tester) async {
      final fetcher = _FakeGameDetailFetcher(game: _testGame);
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(_buildTestApp(
          model,
          fetcher: fetcher,
          services: _FakeGameServices(favs, ignored, playLog),
        ));
        await tester.pump();
      });

      expect(find.text('Wingspan'), findsOneWidget);
    });

    testWidgets('shows error message on fetch failure', (tester) async {
      final fetcher = _FakeGameDetailFetcher(error: Exception('network error'));
      await tester.pumpWidget(_buildTestApp(model, fetcher: fetcher));
      await tester.pump();

      expect(find.text('Failed to load game'), findsOneWidget);
    });

    testWidgets('calls fetchGame with the provided gameId', (tester) async {
      final fetcher = _FakeGameDetailFetcher(game: _testGame);
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(_buildTestApp(
          model,
          fetcher: fetcher,
          services: _FakeGameServices(favs, ignored, playLog),
          gameId: 99,
        ));
        await tester.pump();
      });

      expect(fetcher.callCount, 1);
    });

    testWidgets('does not refetch on rebuild', (tester) async {
      final fetcher = _FakeGameDetailFetcher(game: _testGame);
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(_buildTestApp(
          model,
          fetcher: fetcher,
          services: _FakeGameServices(favs, ignored, playLog),
        ));
        await tester.pump();
        await tester.pump();
        await tester.pump();
      });

      expect(fetcher.callCount, 1);
    });

    testWidgets('renders game action buttons when services loaded',
        (tester) async {
      final fetcher = _FakeGameDetailFetcher(game: _testGame);
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(_buildTestApp(
          model,
          fetcher: fetcher,
          services: _FakeGameServices(favs, ignored, playLog),
        ));
        await tester.pump();
        await tester.pump();
      });

      expect(find.text('Favourite'), findsOneWidget);
    });
  });
}
