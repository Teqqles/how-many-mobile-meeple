import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'play_log_entry.dart';

/// Stores a chronological history of games the user has played.
///
/// Unlike favourites/ignored (which are sets keyed by game id), the play log
/// allows the same game to appear many times — one entry per play. Entries are
/// persisted to [SharedPreferences] as JSON and always exposed newest-first.
class PlayLogService extends ChangeNotifier {
  static const String storageKey = 'play_log';

  static PlayLogService? _instance;
  static Future<PlayLogService>? _instanceFuture;

  List<PlayLogEntry> _entries = [];

  // Derived indices kept in sync with [_entries] so per-game lookups are O(1)
  // even when called inside sort comparators over a large collection.
  final Map<int, int> _playCounts = {};
  final Map<int, DateTime> _lastPlayed = {};

  PlayLogService._();

  static Future<PlayLogService> instance() {
    if (_instance != null) return Future.value(_instance!);
    return _instanceFuture ??= _create();
  }

  static Future<PlayLogService> _create() async {
    final svc = PlayLogService._();
    await svc.load();
    _instance = svc;
    return svc;
  }

  static PlayLogService? get cached => _instance;

  static void resetForTesting() {
    _instance = null;
    _instanceFuture = null;
  }

  /// All logged plays, most recently played first.
  List<PlayLogEntry> get entries => List.unmodifiable(_entries);

  /// The most recent time [gameId] was played, or null if never logged.
  DateTime? lastPlayed(int gameId) => _lastPlayed[gameId];

  /// How many times [gameId] has been logged.
  int playCount(int gameId) => _playCounts[gameId] ?? 0;

  /// Distinct player names ordered by how often they appear across all plays,
  /// most frequent first. Used to suggest people the user plays with regularly.
  List<String> frequentPlayers() {
    final counts = <String, int>{};
    for (final entry in _entries) {
      for (final player in entry.players) {
        counts.update(player.name, (c) => c + 1, ifAbsent: () => 1);
      }
    }
    final names = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    return names;
  }

  void logPlay(PlayLogEntry entry) {
    _entries.add(entry);
    _rebuildDerived();
    _save();
    notifyListeners();
  }

  /// Replaces the entry sharing [entry]'s id. No-op if the id isn't found.
  void update(PlayLogEntry entry) {
    final index = _entries.indexWhere((e) => e.id == entry.id);
    if (index < 0) return;
    _entries[index] = entry;
    _rebuildDerived();
    _save();
    notifyListeners();
  }

  void remove(String id) {
    _entries.removeWhere((e) => e.id == id);
    _rebuildDerived();
    _save();
    notifyListeners();
  }

  /// Sorts entries newest-first and rebuilds the per-game count/last-played
  /// indices. Entries are already sorted, so the first entry seen for a game
  /// is its most recent play.
  void _rebuildDerived() {
    _entries.sort((a, b) => b.playedAt.compareTo(a.playedAt));
    _playCounts.clear();
    _lastPlayed.clear();
    for (final entry in _entries) {
      _playCounts.update(entry.gameId, (c) => c + 1, ifAbsent: () => 1);
      _lastPlayed.putIfAbsent(entry.gameId, () => entry.playedAt);
    }
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null) return;
    final list = jsonDecode(raw) as List;
    _entries = list
        .map((e) => PlayLogEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    _rebuildDerived();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_entries.map((e) => e.toJson()).toList());
    await prefs.setString(storageKey, encoded);
  }
}
