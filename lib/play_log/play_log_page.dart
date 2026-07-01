import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:how_many_mobile_meeple/app_page.dart';
import 'package:how_many_mobile_meeple/components/feature_drawer.dart';
import 'package:how_many_mobile_meeple/components/game_thumbnail.dart';
import 'package:how_many_mobile_meeple/components/list_empty_state.dart';
import 'package:how_many_mobile_meeple/how_many_meeple_app_bar.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/model/play_data.dart';
import 'log_play_dialog.dart';
import 'play_date_format.dart';
import 'play_log_entry.dart';
import 'play_log_service.dart';

/// One row in the merged play history: either a locally logged play (editable)
/// or a play loaded from BGG (read-only, badged with the BGG logo).
class _HistoryItem {
  final PlayLogEntry? local;
  final BggPlayRecord? bgg;

  _HistoryItem.local(this.local) : bgg = null;
  _HistoryItem.bgg(this.bgg) : local = null;

  bool get isBgg => bgg != null;

  int get gameId => local?.gameId ?? bgg!.gameId;

  String get name => local?.name ?? bgg!.gameName;

  String? get thumbnail => local?.thumbnail ?? bgg?.thumbnail;

  /// A stable date used for sorting; BGG plays with no date sort last.
  DateTime get date =>
      local?.playedAt ??
      bgg!.play.date ??
      DateTime.fromMillisecondsSinceEpoch(0);
}

/// Chronological history of plays, newest first.
///
/// Merges locally logged plays with individual plays loaded from BGG. Local
/// plays can be edited or removed; BGG plays are shown read-only and badged.
/// A nudge appears when a previously regular game hasn't been played in a
/// while.
class PlayLogPage extends StatefulWidget {
  const PlayLogPage({super.key});

  @override
  State<PlayLogPage> createState() => _PlayLogPageState();
}

class _PlayLogPageState extends State<PlayLogPage> with AppPage {
  PlayLogService? _service;

  @override
  void initState() {
    super.initState();
    _loadService();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final model = AppModel.of(context, listen: false);
      if (!model.playsLoaded && model.primaryPlayer != null) {
        model.loadPlays();
      }
    });
  }

  Future<void> _loadService() async {
    final service = await PlayLogService.instance();
    service.addListener(_onChanged);
    if (mounted) setState(() => _service = service);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _service?.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HowManyMeepleAppBar('Play History', context: context),
      drawer: const FeatureDrawer(),
      endDrawer: pageDrawer(context),
      body: _service == null
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(context, AppModel.of(context)),
    );
  }

  List<_HistoryItem> _mergedItems(AppModel model) {
    final items = <_HistoryItem>[
      for (final entry in _service!.entries) _HistoryItem.local(entry),
      for (final record in model.bggPlays) _HistoryItem.bgg(record),
    ];
    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  Widget _buildBody(BuildContext context, AppModel model) {
    final items = _mergedItems(model);
    if (items.isEmpty) {
      return _buildEmptyState(context);
    }

    final nudge = _buildNudge(context, items);
    return ListView.builder(
      itemCount: items.length + (nudge != null ? 1 : 0),
      itemBuilder: (context, index) {
        if (nudge != null && index == 0) return nudge;
        final item = items[index - (nudge != null ? 1 : 0)];
        return _buildRow(context, item, index);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return const ListEmptyState(
      icon: Icons.history,
      title: 'No plays logged yet',
      description:
          'Tap "Played it" on a game to start building your play history.',
    );
  }

  Widget _buildRow(BuildContext context, _HistoryItem item, int index) {
    // BGG plays live upstream and are shown read-only, so they aren't
    // dismissible and tapping them does nothing.
    if (item.isBgg) {
      return _buildTile(context, item, index);
    }
    final entry = item.local!;
    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Theme.of(context).colorScheme.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _service!.remove(entry.id),
      child: _buildTile(context, item, index),
    );
  }

  /// Surfaces a game the user used to play but hasn't in 3+ months, nudging
  /// them to bring it back. Picks the neglected game with the most plays (a
  /// former regular), so recent activity on other games never suppresses it.
  Widget? _buildNudge(BuildContext context, List<_HistoryItem> items) {
    // items is sorted newest-first, so the first row seen for a game holds its
    // most recent play (why putIfAbsent below records the latest date).
    final playCounts = <int, int>{};
    final lastPlayed = <int, DateTime>{};
    final names = <int, String>{};
    for (final item in items) {
      final id = item.gameId;
      playCounts.update(id, (c) => c + 1, ifAbsent: () => 1);
      lastPlayed.putIfAbsent(id, () => item.date);
      names.putIfAbsent(id, () => item.name);
    }

    int? neglectedId;
    for (final id in playCounts.keys) {
      if (PlayDateFormat.monthsSince(lastPlayed[id]!) < 3) continue;
      if (neglectedId == null || playCounts[id]! > playCounts[neglectedId]!) {
        neglectedId = id;
      }
    }
    if (neglectedId == null) return null;

    final months = PlayDateFormat.monthsSince(lastPlayed[neglectedId]!);
    final name = names[neglectedId]!;
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline,
              color: Theme.of(context).colorScheme.onTertiaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "You haven't played $name in $months months — "
              'time to bring it back to the table?',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onTertiaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(BuildContext context, _HistoryItem item, int index) {
    final isEven = index % 2 == 0;
    final thumbnail = item.thumbnail;
    final hasPlayers = item.isBgg
        ? item.bgg!.play.players.isNotEmpty
        : item.local!.players.isNotEmpty;

    return Material(
      color: isEven
          ? Colors.transparent
          : Theme.of(context).colorScheme.primary.withAlpha(8),
      child: ListTile(
        leading: GameThumbnail(thumbnail: thumbnail),
        title: Row(
          children: [
            Flexible(child: Text(item.name)),
            if (item.isBgg) ...[
              const SizedBox(width: 8),
              _bggBadge(context),
            ],
          ],
        ),
        subtitle: Text(_buildSubtitle(item)),
        isThreeLine: hasPlayers,
        trailing: item.isBgg
            ? null
            : IconButton(
                icon: Icon(Icons.remove_circle_outline,
                    color: Theme.of(context).colorScheme.error),
                tooltip: 'Remove',
                onPressed: () => _service!.remove(item.local!.id),
              ),
        onTap: item.isBgg ? null : () => _editEntry(item.local!),
      ),
    );
  }

  Widget _bggBadge(BuildContext context) {
    // The BGG logo asset is a single white shape; tint it with the theme
    // colour so it reads on our light surfaces and matches the app.
    return SvgPicture.asset(
      'lib/images/bgg-logo.svg',
      height: 16,
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(
        Theme.of(context).colorScheme.primary,
        BlendMode.srcIn,
      ),
      semanticsLabel: 'Loaded from BoardGameGeek',
    );
  }

  Future<void> _editEntry(PlayLogEntry entry) async {
    final updated = await LogPlayDialog.show(
      context,
      existing: entry,
      suggestedPlayers: _service!.frequentPlayers(),
    );
    if (updated != null) _service!.update(updated);
  }

  String _buildSubtitle(_HistoryItem item) {
    if (item.isBgg) {
      final play = item.bgg!.play;
      final date = play.date;
      final buffer = StringBuffer(
          date != null ? PlayDateFormat.relative(date) : 'Date unknown');
      if (play.players.isNotEmpty) {
        buffer.write('\n');
        buffer.write(play.players
            .map((p) => _formatParticipant(p.name, p.score, p.win))
            .join(', '));
      }
      return buffer.toString();
    }

    final entry = item.local!;
    final buffer = StringBuffer(PlayDateFormat.relative(entry.playedAt));
    if (entry.players.isNotEmpty) {
      buffer.write('\n');
      buffer.write(entry.players
          .map((p) => _formatParticipant(p.name, p.score, p.won))
          .join(', '));
    }
    return buffer.toString();
  }

  String _formatParticipant(String name, int? score, bool won) {
    final parts = StringBuffer(name);
    if (score != null) parts.write(' ($score)');
    if (won) parts.write(' 🏆');
    return parts.toString();
  }
}
