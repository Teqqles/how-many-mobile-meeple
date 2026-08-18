import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:how_many_mobile_meeple/components/platform_independent_image.dart';
import 'package:how_many_mobile_meeple/favourites/favourites_service.dart';
import 'package:how_many_mobile_meeple/favourites/ignored_games_service.dart';
import 'package:how_many_mobile_meeple/model/game.dart';
import 'package:how_many_mobile_meeple/model/game_night.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';
import 'package:how_many_mobile_meeple/platform/router.dart' as r;
import 'package:share_plus/share_plus.dart';

/// Recommends a full evening's lineup - a filler, a main game and a backup -
/// from a pool of games within a chosen time budget. The user can pin any slot
/// and regenerate the rest. The optional expansion slot is deferred until the
/// backend exposes expansion relationships (issue #119).
class GameNightView extends StatefulWidget {
  final AppModel model;
  final List<Game> pool;
  final GameNightPlanner planner;

  GameNightView({
    super.key,
    required this.model,
    required this.pool,
    GameNightPlanner? planner,
  }) : planner = planner ?? GameNightPlanner();

  @override
  State<GameNightView> createState() => _GameNightViewState();
}

class _GameNightViewState extends State<GameNightView> {
  static const List<_DurationPreset> _presets = [
    _DurationPreset('2h', 120),
    _DurationPreset('3h', 180),
    _DurationPreset('4h', 240),
    _DurationPreset('5h', 300),
  ];

  /// How many mechanics to offer per slot, most common in the pool first.
  static const int _maxMechanicOptions = 12;

  final Map<GameNightSlot, Game> _pinned = {};
  final Map<GameNightSlot, String> _slotMechanics = {};
  GameNightLineup _lineup = const GameNightLineup();
  _PlayFilter _playFilter = _PlayFilter.all;

  static const List<int> _playerCounts = [1, 2, 3, 4, 5, 6, 7, 8];

  int get _durationMinutes => widget.model.settings
      .setting(Settings.gameNightDurationMinutes.name)
      .getInt();

  /// The chosen game-night player count, or null for "any". Null starts the
  /// pool from the whole collection; a value narrows it to games that seat
  /// that many players.
  int? get _playerCount {
    final setting = widget.model.settings.setting(
      Settings.gameNightPlayerCount.name,
    );
    return setting.enabled ? setting.getInt() : null;
  }

  /// The outro is only relevant on a long night; the toggle and slot stay
  /// hidden below the planner's threshold.
  bool get _outroApplies =>
      _durationMinutes > GameNightPlanner.outroMinDurationMinutes;

  bool get _includeOutro =>
      widget.model.settings.setting(Settings.gameNightOutro.name).getBool();

  /// The pool the planner draws from: ignored games are never suggested, and
  /// the play-history filter narrows it further. Filtering by plays needs the
  /// play counts, so it only applies once plays have loaded; otherwise every
  /// game would look unplayed.
  List<Game> get _effectivePool {
    final pool = _withoutIgnored(widget.pool);
    if (_playFilter == _PlayFilter.all || !widget.model.playsLoaded) {
      return pool;
    }
    final wantPlayed = _playFilter == _PlayFilter.played;
    return pool
        .where((g) => (widget.model.getPlayCount(g.id) > 0) == wantPlayed)
        .toList();
  }

  List<Game> _withoutIgnored(List<Game> games) {
    final ignored = IgnoredGamesService.cached;
    if (ignored == null) return games;
    return games.where((g) => !ignored.contains(g.id)).toList();
  }

  /// Mechanics available in the pool, most common first. Sourced from the pool
  /// itself (the game-night fetch whitelists `mechanics`) so every option is
  /// guaranteed to match at least one game.
  List<String> get _poolMechanics {
    final counts = <String, int>{};
    for (final game in widget.pool) {
      for (final mechanic in game.mechanics) {
        counts[mechanic] = (counts[mechanic] ?? 0) + 1;
      }
    }
    final sorted = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    return sorted.take(_maxMechanicOptions).toList();
  }

  @override
  void initState() {
    super.initState();
    _restoreSharedLineup();
    _regenerate();
  }

  /// Pins the games carried by a shared permalink so the recipient sees the
  /// exact lineup, then consumes the token so it neither persists nor re-pins
  /// on later visits. Any game the shared collection no longer contains is
  /// skipped, leaving that slot to regenerate normally.
  void _restoreSharedLineup() {
    final setting = widget.model.settings.setting(
      Settings.gameNightLineup.name,
    );
    if (!setting.enabled) return;
    final token = setting.getString();
    if (token.isEmpty) return;

    GameNightPermalink.decode(token).forEach((slot, id) {
      final game = _findInPool(id);
      if (game != null) _pinned[slot] = game;
    });
    _consumeSharedLineup();
  }

  Game? _findInPool(int id) {
    for (final game in widget.pool) {
      if (game.id == id) return game;
    }
    return null;
  }

  void _consumeSharedLineup() {
    final setting = widget.model.settings.setting(Settings.gameNightLineup.name)
      ..value = ''
      ..enabled = false;
    widget.model.settings.updateSetting(setting);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.model.updateStore(),
    );
  }

  Future<void> _share() async {
    final url = r.Router.gameNightPermalink(widget.model, _lineup);
    try {
      await SharePlus.instance.share(
        ShareParams(
          title: 'My game night on How Many Meeple',
          uri: Uri.parse(url),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      await Clipboard.setData(ClipboardData(text: url));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Game night link copied to clipboard')),
      );
    }
  }

  @override
  void didUpdateWidget(GameNightView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A fresh fetch (e.g. after a source change) hands us a new pool list.
    if (!identical(oldWidget.pool, widget.pool)) _regenerate();
  }

  void _regenerate() {
    setState(() {
      _lineup = widget.planner.plan(
        pool: _effectivePool,
        durationMinutes: _durationMinutes,
        pinned: Map.of(_pinned),
        slotMechanics: Map.of(_slotMechanics),
        includeOutro: _includeOutro,
        favouriteIds: _favouriteIds,
      );
    });
  }

  Set<int> get _favouriteIds {
    final favourites = FavouritesService.cached;
    if (favourites == null) return const {};
    return favourites.games.map((g) => g.id).toSet();
  }

  /// The outro plays from the pool already in hand, so toggling it re-plans
  /// locally; the choice is persisted so it sticks across visits.
  void _setIncludeOutro(bool enabled) {
    final setting = widget.model.settings.setting(Settings.gameNightOutro.name)
      ..value = enabled
      ..enabled = true;
    widget.model.settings.updateSetting(setting);
    widget.model.updateStore();
    _regenerate();
  }

  /// Filtering a slot by mechanic works on the pool already in hand, so it
  /// re-plans locally without a refetch.
  void _setSlotMechanic(GameNightSlot slot, String? mechanic) {
    if (mechanic == null) {
      _slotMechanics.remove(slot);
    } else {
      _slotMechanics[slot] = mechanic;
    }
    _regenerate();
  }

  void _setPlayFilter(_PlayFilter filter) {
    if (filter == _playFilter) return;
    _playFilter = filter;
    _regenerate();
  }

  /// Changing the player count reshapes the fetched pool, so it writes the
  /// setting and lets the store update trigger a refetch; the new pool then
  /// re-plans the lineup through didUpdateWidget.
  void _setPlayerCount(int? count) {
    final setting = widget.model.settings.setting(
      Settings.gameNightPlayerCount.name,
    );
    setting.enabled = count != null;
    if (count != null) setting.value = count;
    widget.model.settings.updateSetting(setting);
    widget.model.updateStore();
  }

  void _setDuration(int minutes) {
    final setting = widget.model.settings.setting(
      Settings.gameNightDurationMinutes.name,
    );
    setting.value = minutes;
    setting.enabled = true;
    widget.model.settings.updateSetting(setting);
    widget.model.updateStore();
    _regenerate();
  }

  void _togglePin(GameNightSlot slot) {
    final game = _lineup.slot(slot);
    setState(() {
      if (_pinned.containsKey(slot)) {
        _pinned.remove(slot);
      } else if (game != null) {
        _pinned[slot] = game;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pool.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Load a collection to plan a game night.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildDurationPicker(context),
          const SizedBox(height: 16),
          _buildPlayerCountPicker(context),
          if (widget.model.playsLoaded) ...[
            const SizedBox(height: 16),
            _buildPlayFilter(context),
          ],
          if (_outroApplies) ...[
            const SizedBox(height: 8),
            _buildOutroToggle(context),
          ],
          const SizedBox(height: 20),
          _buildSlot(context, GameNightSlot.filler, 'Filler', 'Warm-up', 0),
          _buildSlot(context, GameNightSlot.main, 'Main', 'The centrepiece', 1),
          _buildSlot(
            context,
            GameNightSlot.backup,
            'Backup',
            'If the mood shifts',
            2,
          ),
          if (_outroApplies && _includeOutro)
            _buildSlot(
              context,
              GameNightSlot.outro,
              'Outro',
              'Wind-down closer',
              3,
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  key: const ValueKey('game-night-regenerate'),
                  onPressed: _regenerate,
                  icon: const Icon(Icons.casino),
                  label: const Text('Regenerate'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                key: const ValueKey('game-night-share'),
                onPressed: _lineup.isEmpty ? null : _share,
                icon: const Icon(Icons.share),
                label: const Text('Share'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDurationPicker(BuildContext context) {
    final duration = _durationMinutes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Evening length', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final preset in _presets)
              ChoiceChip(
                label: Text(preset.label),
                selected: duration == preset.minutes,
                onSelected: (_) => _setDuration(preset.minutes),
              ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Slider(
                min: 60,
                max: 360,
                divisions: 20,
                value: duration.clamp(60, 360).toDouble(),
                label: _formatDuration(duration),
                onChanged: (value) => _setDuration(value.round()),
              ),
            ),
            SizedBox(
              width: 56,
              child: Text(_formatDuration(duration), textAlign: TextAlign.end),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOutroToggle(BuildContext context) {
    return SwitchListTile(
      key: const ValueKey('game-night-outro-toggle'),
      contentPadding: EdgeInsets.zero,
      title: const Text('End with a wind-down game'),
      subtitle: const Text('A short closer after the main, on a long night'),
      value: _includeOutro,
      onChanged: _setIncludeOutro,
    );
  }

  Widget _buildPlayerCountPicker(BuildContext context) {
    final selected = _playerCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Players', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Any'),
              selected: selected == null,
              onSelected: (_) => _setPlayerCount(null),
            ),
            for (final count in _playerCounts)
              ChoiceChip(
                label: Text('$count'),
                selected: selected == count,
                onSelected: (_) => _setPlayerCount(count),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlayFilter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Play history', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SegmentedButton<_PlayFilter>(
          segments: const [
            ButtonSegment(value: _PlayFilter.all, label: Text('Show all')),
            ButtonSegment(value: _PlayFilter.unplayed, label: Text('Unplayed')),
            ButtonSegment(value: _PlayFilter.played, label: Text('Played')),
          ],
          selected: {_playFilter},
          showSelectedIcon: false,
          onSelectionChanged: (selection) => _setPlayFilter(selection.first),
        ),
      ],
    );
  }

  Widget _buildSlot(
    BuildContext context,
    GameNightSlot slot,
    String title,
    String subtitle,
    int index,
  ) {
    final game = _lineup.slot(slot);
    final pinned = _pinned.containsKey(slot);
    final scheme = Theme.of(context).colorScheme;
    // Alternating row tints make the three slots easier to scan apart.
    final stripe = index.isEven
        ? scheme.surfaceContainerHighest
        : scheme.surfaceContainerLow;
    return Card(
      color: stripe,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (game != null) ...[
              _buildThumbnail(context, game),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$title · $subtitle',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (game != null) ...[
                    Text(
                      game.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    _buildGameDetails(context, game),
                  ] else
                    Text(
                      'No fit for this slot',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  _buildSlotMechanic(context, slot),
                ],
              ),
            ),
            if (game != null)
              IconButton(
                tooltip: pinned ? 'Unpin' : 'Pin',
                icon: Icon(pinned ? Icons.push_pin : Icons.push_pin_outlined),
                color: pinned ? Theme.of(context).colorScheme.primary : null,
                onPressed: () => _togglePin(slot),
              ),
          ],
        ),
      ),
    );
  }

  /// A compact per-slot mechanic quick-pick. Hidden until the pool carries
  /// mechanics, so it degrades gracefully when the field is unavailable.
  Widget _buildSlotMechanic(BuildContext context, GameNightSlot slot) {
    final options = _poolMechanics;
    if (options.isEmpty) return const SizedBox.shrink();
    final selected = _slotMechanics[slot];
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.tune, size: 14, color: color),
          const SizedBox(width: 4),
          DropdownButton<String?>(
            key: ValueKey('game-night-mechanic-${slot.name}'),
            value: selected,
            isDense: true,
            underline: const SizedBox.shrink(),
            hint: Text(
              'Any mechanic',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: color),
            ),
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: color),
            items: [
              const DropdownMenuItem(value: null, child: Text('Any mechanic')),
              for (final mechanic in options)
                DropdownMenuItem(value: mechanic, child: Text(mechanic)),
            ],
            onChanged: (value) => _setSlotMechanic(slot, value),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context, Game game) {
    final url = (game.thumbnail?.isNotEmpty ?? false)
        ? game.thumbnail!
        : game.imageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 64,
        height: 64,
        child: url.isEmpty
            ? Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.casino,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            : PlatformIndependentImage(imageUrl: url, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildGameDetails(BuildContext context, Game game) {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        _detail(context, Icons.schedule, '${game.maxPlaytime} min'),
        _detail(context, Icons.people_outline, _playerRange(game)),
        if (game.averageRating > 0)
          _detail(
            context,
            Icons.star_outline,
            game.averageRating.toStringAsFixed(1),
          ),
        _detail(
          context,
          Icons.fitness_center,
          _weightLabel(game.averageWeight),
        ),
        if (widget.model.playsLoaded)
          _detail(context, Icons.history, _playsLabel(game)),
      ],
    );
  }

  String _playsLabel(Game game) {
    final plays = widget.model.getPlayCount(game.id);
    return plays > 0 ? 'Played $plays×' : 'Unplayed';
  }

  Widget _detail(BuildContext context, IconData icon, String text) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 3),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
        ),
      ],
    );
  }

  static String _playerRange(Game game) {
    if (game.minPlayers == game.maxPlayers) return '${game.maxPlayers} players';
    return '${game.minPlayers}-${game.maxPlayers} players';
  }

  static String _formatDuration(int minutes) {
    final hours = minutes / 60;
    if (minutes % 60 == 0) return '${minutes ~/ 60}h';
    return '${hours.toStringAsFixed(1)}h';
  }

  static String _weightLabel(double weight) {
    if (weight < 2.0) return 'Light';
    if (weight <= 3.0) return 'Medium';
    return 'Heavy';
  }
}

class _DurationPreset {
  final String label;
  final int minutes;

  const _DurationPreset(this.label, this.minutes);
}

/// Filters the pool by whether the primary player has logged plays of a game,
/// so an evening can favour familiar games for teaching or fresh ones to try.
enum _PlayFilter { all, unplayed, played }
