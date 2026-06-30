import 'game_list_service.dart';
import 'ignored_games_service.dart';

class FavouritesService extends GameListService {
  static FavouritesService? _instance;
  static Future<FavouritesService>? _instanceFuture;

  FavouritesService._() : super('favourite_games');

  static Future<FavouritesService> instance() {
    if (_instance != null) return Future.value(_instance!);
    return _instanceFuture ??= _create();
  }

  static Future<FavouritesService> _create() async {
    final svc = FavouritesService._();
    await svc.load();
    final ignored = IgnoredGamesService.cached;
    if (ignored != null) svc.linkOpposite(ignored);
    _instance = svc;
    return svc;
  }

  static FavouritesService? get cached => _instance;

  static void resetForTesting() {
    _instance = null;
    _instanceFuture = null;
  }
}
