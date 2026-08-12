import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'recently_viewed_game.dart';

/// Tracks the games the user has most recently viewed, newest first, capped at
/// [maxEntries]. Backed by SharedPreferences and captured at view time, so the
/// list renders without any further API calls.
class RecentlyViewedService extends ChangeNotifier {
  static const String storageKey = 'recently_viewed_games';
  static const int maxEntries = 10;

  static RecentlyViewedService? _instance;
  static Future<RecentlyViewedService>? _instanceFuture;

  final List<RecentlyViewedGame> _games = [];

  List<RecentlyViewedGame> get games => List.unmodifiable(_games);

  RecentlyViewedService._();

  static Future<RecentlyViewedService> instance() {
    if (_instance != null) return Future.value(_instance!);
    return _instanceFuture ??= _create();
  }

  static RecentlyViewedService? get cached => _instance;

  static Future<RecentlyViewedService> _create() async {
    final svc = RecentlyViewedService._();
    await svc.load();
    _instance = svc;
    return svc;
  }

  static void resetForTesting() {
    _instance = null;
    _instanceFuture = null;
  }

  /// Records [game] as the most recently viewed. A no-op when it is already the
  /// most recent entry, so repeated views of the same game (e.g. rebuilds of
  /// the random page) neither reorder the list nor trigger a redundant write.
  void add(RecentlyViewedGame game) {
    if (_games.isNotEmpty && _games.first.id == game.id) return;
    _games.removeWhere((g) => g.id == game.id);
    _games.insert(0, game);
    if (_games.length > maxEntries) {
      _games.removeRange(maxEntries, _games.length);
    }
    _save();
    notifyListeners();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null) return;
    final list = jsonDecode(raw) as List;
    _games
      ..clear()
      ..addAll(list.map((e) => RecentlyViewedGame.fromJson(e)));
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_games.map((g) => g.toJson()).toList());
    await prefs.setString(storageKey, encoded);
  }
}
