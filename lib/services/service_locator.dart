import 'package:flutter/widgets.dart';
import 'package:flutter_inject/flutter_inject.dart';
import 'package:how_many_mobile_meeple/api/game_detail_service.dart';
import 'package:how_many_mobile_meeple/api/recommendations_service.dart';
import 'package:how_many_mobile_meeple/favourites/favourites_service.dart';
import 'package:how_many_mobile_meeple/favourites/ignored_games_service.dart';
import 'package:how_many_mobile_meeple/play_log/play_log_service.dart';
import 'package:how_many_mobile_meeple/model/game.dart';
import 'package:how_many_mobile_meeple/model/recommendation.dart';

abstract class GameDetailFetcher {
  Future<Game> fetchGame(int gameId);
}

abstract class RecommendationsFetcher {
  Future<List<Recommendation>> fetchRecommendations({
    required List<int> gameIds,
    required Map<String, String> headers,
    int limit = 10,
    List<int> excludeIds = const [],
  });
}

abstract class GameServices {
  Future<FavouritesService> favourites();
  Future<IgnoredGamesService> ignored();
  Future<PlayLogService> playLog();
}

class DefaultGameDetailFetcher implements GameDetailFetcher {
  @override
  Future<Game> fetchGame(int gameId) => GameDetailService.fetchGame(gameId);
}

class DefaultRecommendationsFetcher implements RecommendationsFetcher {
  @override
  Future<List<Recommendation>> fetchRecommendations({
    required List<int> gameIds,
    required Map<String, String> headers,
    int limit = 10,
    List<int> excludeIds = const [],
  }) =>
      RecommendationsService.fetchRecommendations(
        gameIds: gameIds,
        headers: headers,
        limit: limit,
        excludeIds: excludeIds,
      );
}

class DefaultGameServices implements GameServices {
  @override
  Future<FavouritesService> favourites() => FavouritesService.instance();
  @override
  Future<IgnoredGamesService> ignored() => IgnoredGamesService.instance();
  @override
  Future<PlayLogService> playLog() => PlayLogService.instance();
}

extension ServiceLocator on BuildContext {
  GameDetailFetcher get gameDetailFetcher =>
      Dependency.maybeGet<GameDetailFetcher>(this) ??
      DefaultGameDetailFetcher();

  RecommendationsFetcher get recommendationsFetcher =>
      Dependency.maybeGet<RecommendationsFetcher>(this) ??
      DefaultRecommendationsFetcher();

  GameServices get gameServices =>
      Dependency.maybeGet<GameServices>(this) ?? DefaultGameServices();
}
