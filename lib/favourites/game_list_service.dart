import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'favourite_game.dart';

abstract class GameListService extends ChangeNotifier {
  final String storageKey;
  GameListService? _opposite;

  List<FavouriteGame> _games = [];

  List<FavouriteGame> get games => List.unmodifiable(_games);

  GameListService(this.storageKey);

  void linkOpposite(GameListService other) {
    _opposite = other;
    other._opposite = this;
  }

  bool contains(int gameId) => _games.any((g) => g.id == gameId);

  void toggle(FavouriteGame game) {
    final index = _games.indexWhere((g) => g.id == game.id);
    if (index >= 0) {
      _games.removeAt(index);
    } else {
      _games.insert(0, game);
      _opposite?.remove(game.id);
    }
    _save();
    notifyListeners();
  }

  void remove(int gameId) {
    _games.removeWhere((g) => g.id == gameId);
    _save();
    notifyListeners();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null) return;
    final list = jsonDecode(raw) as List;
    _games = list.map((e) => FavouriteGame.fromJson(e)).toList();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_games.map((g) => g.toJson()).toList());
    await prefs.setString(storageKey, encoded);
  }
}
