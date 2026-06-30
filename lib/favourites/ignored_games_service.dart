import 'favourites_service.dart';
import 'game_list_service.dart';

class IgnoredGamesService extends GameListService {
  static IgnoredGamesService? _instance;
  static Future<IgnoredGamesService>? _instanceFuture;

  IgnoredGamesService._() : super('ignored_games');

  static Future<IgnoredGamesService> instance() {
    if (_instance != null) return Future.value(_instance!);
    return _instanceFuture ??= _create();
  }

  static Future<IgnoredGamesService> _create() async {
    final svc = IgnoredGamesService._();
    await svc.load();
    final favs = FavouritesService.cached;
    if (favs != null) svc.linkOpposite(favs);
    _instance = svc;
    return svc;
  }

  static IgnoredGamesService? get cached => _instance;

  static void resetForTesting() {
    _instance = null;
    _instanceFuture = null;
  }
}
