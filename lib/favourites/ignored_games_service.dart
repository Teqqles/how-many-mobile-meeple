import 'favourites_service.dart';
import 'game_list_service.dart';

class IgnoredGamesService extends GameListService {
  static IgnoredGamesService? _instance;

  IgnoredGamesService._() : super('ignored_games');

  static Future<IgnoredGamesService> instance() async {
    if (_instance != null) return _instance!;
    _instance = IgnoredGamesService._();
    await _instance!.load();
    final favs = FavouritesService.cached;
    if (favs != null) _instance!.linkOpposite(favs);
    return _instance!;
  }

  static IgnoredGamesService? get cached => _instance;

  static void resetForTesting() => _instance = null;
}
