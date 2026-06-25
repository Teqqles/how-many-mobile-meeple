import 'game_list_service.dart';
import 'ignored_games_service.dart';

class FavouritesService extends GameListService {
  static FavouritesService? _instance;

  FavouritesService._() : super('favourite_games');

  static Future<FavouritesService> instance() async {
    if (_instance != null) return _instance!;
    _instance = FavouritesService._();
    await _instance!.load();
    final ignored = IgnoredGamesService.cached;
    if (ignored != null) _instance!.linkOpposite(ignored);
    return _instance!;
  }

  static FavouritesService? get cached => _instance;

  static void resetForTesting() => _instance = null;
}
