import 'package:how_many_mobile_meeple/model/play_data.dart';

/// One game in the "most played" ranking.
class MostPlayedEntry {
  final int gameId;
  final String name;
  final int plays;

  const MostPlayedEntry(
      {required this.gameId, required this.name, required this.plays});
}

/// Play tally for a single calendar year. [plays] counts every recorded play;
/// [collectionPlays] counts only those of games in the current collection.
class YearPlays {
  final int year;
  final int plays;
  final int collectionPlays;

  const YearPlays(
      {required this.year, required this.plays, this.collectionPlays = 0});
}

/// Insights derived from the primary player's plays and collection, computed
/// entirely client-side from data already loaded by the model. Pure and
/// dependency-free so it is trivially testable.
class PlayInsights {
  final int totalGames;
  final int playedGames;
  final int totalPlays;
  final int totalMinutes;
  final int playsThisYear;
  final int playedOnce;
  final int playedRepeatedly;
  final List<MostPlayedEntry> mostPlayed;
  final List<YearPlays> playsPerYear;

  const PlayInsights({
    required this.totalGames,
    required this.playedGames,
    required this.totalPlays,
    required this.totalMinutes,
    required this.playsThisYear,
    required this.playedOnce,
    required this.playedRepeatedly,
    required this.mostPlayed,
    required this.playsPerYear,
  });

  int get unplayedGames => totalGames - playedGames;

  /// True when there is anything play-related worth showing.
  bool get hasPlays => totalPlays > 0;

  factory PlayInsights.from({
    required Set<int> collectionGameIds,
    required Map<int, PlayData> playsData,
    required int Function(int gameId) playCount,
    required DateTime now,
    int topN = 8,
  }) {
    // Backlog (played/unplayed) is a property of the owned collection, so it
    // stays collection-scoped. Play activity and most-played span everything
    // that has been played, including games no longer (or never) owned.
    final allIds = <int>{...collectionGameIds, ...playsData.keys};

    var collectionPlayed = 0;
    var playedOnce = 0;
    var playedRepeatedly = 0;
    var totalPlays = 0;
    final ranked = <MostPlayedEntry>[];

    for (final id in allIds) {
      final count = playCount(id);
      totalPlays += count;
      if (count > 0) {
        if (count == 1) {
          playedOnce++;
        } else {
          playedRepeatedly++;
        }
        if (collectionGameIds.contains(id)) collectionPlayed++;
        ranked.add(MostPlayedEntry(
          gameId: id,
          name: playsData[id]?.gameName ?? 'Game #$id',
          plays: count,
        ));
      }
    }

    ranked.sort((a, b) {
      final byPlays = b.plays.compareTo(a.plays);
      return byPlays != 0 ? byPlays : a.name.compareTo(b.name);
    });

    var totalMinutes = 0;
    var playsThisYear = 0;
    final perYear = <int, int>{};
    final perYearCollection = <int, int>{};
    for (final data in playsData.values) {
      final owned = collectionGameIds.contains(data.gameId);
      for (final play in data.plays) {
        totalMinutes += play.length;
        final date = play.date;
        if (date != null) {
          perYear[date.year] = (perYear[date.year] ?? 0) + 1;
          if (owned) {
            perYearCollection[date.year] =
                (perYearCollection[date.year] ?? 0) + 1;
          }
          if (date.year == now.year) playsThisYear++;
        }
      }
    }

    final years = perYear.keys.toList()..sort();

    return PlayInsights(
      totalGames: collectionGameIds.length,
      playedGames: collectionPlayed,
      totalPlays: totalPlays,
      totalMinutes: totalMinutes,
      playsThisYear: playsThisYear,
      playedOnce: playedOnce,
      playedRepeatedly: playedRepeatedly,
      mostPlayed: ranked.take(topN).toList(),
      playsPerYear: [
        for (final y in years)
          YearPlays(
            year: y,
            plays: perYear[y]!,
            collectionPlays: perYearCollection[y] ?? 0,
          ),
      ],
    );
  }
}
