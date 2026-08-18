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

/// Recommends an evening's lineup - filler, main and backup - from a pool
/// within a time budget. Any slot can be pinned and the rest regenerated.
/// Expansion slot deferred until the backend exposes expansions (issue #119).
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

  /// Chosen player count, or null for "any". A value narrows the pool to games
  /// that seat that many players; null keeps the whole collection.
  int? get _playerCount {
    final setting = widget.model.settings.setting(
      Settings.gameNightPlayerCount.name,
    );
    return setting.enabled ? setting.getInt() : null;
  }

  /// Outro only matters on a long night; toggle and slot stay hidden below the
  /// planner's threshold.
  bool get _outroApplies =>
      _durationMinutes > GameNightPlanner.outroMinDurationMinutes;

  bool get _includeOutro =>
      widget.model.settings.setting(Settings.gameNightOutro.name).getBool();

  /// The pool the planner draws from: ignored games dropped, then the
  /// play-history filter applied. That filter waits for plays to load, else
  /// every game looks unplayed.
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

  /// Mechanics present in the pool, most common first, so every option matches
  /// at least one game. The game-night fetch whitelists `mechanics`.
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
    _ensureListsLoaded();
    _regenerate();
  }

  /// Ignored and favourites lists cache lazily elsewhere, so may be unloaded
  /// when Game Night opens first. Load them and re-plan, else ignored games
  /// leak in and favourites carry no weight.
  void _ensureListsLoaded() {
    if (IgnoredGamesService.cached != null &&
        FavouritesService.cached != null) {
      return;
    }
    Future.wait([IgnoredGamesService.instance(), FavouritesService.instance()])
        .then((_) {
          if (mounted) _regenerate();
        });
  }

  /// Pins the games a shared permalink carries so the recipient sees the exact
  /// lineup, then consumes the token so it neither persists nor re-pins later.
  /// A game the collection no longer holds is skipped, leaving its slot to
  /// regenerate.
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
        playCounts: _playCounts,
      );
    });
  }

  Set<int> get _favouriteIds {
    final favourites = FavouritesService.cached;
    if (favourites == null) return const {};
    return favourites.games.map((g) => g.id).toSet();
  }

  /// Pool play counts, used to fill an empty slot with a well-played game.
  /// Empty until plays load, so the planner then falls back on length.
  Map<int, int> get _playCounts {
    if (!widget.model.playsLoaded) return const {};
    return {
      for (final game in widget.pool)
        game.id: widget.model.getPlayCount(game.id),
    };
  }

  /// Outro draws from the pool in hand, so toggling re-plans locally; the
  /// choice is persisted so it sticks across visits.
  void _setIncludeOutro(bool enabled) {
    final setting = widget.model.settings.setting(Settings.gameNightOutro.name)
      ..value = enabled
      ..enabled = true;
    widget.model.settings.updateSetting(setting);
    widget.model.updateStore();
    _regenerate();
  }

  /// Slot mechanic filters the pool in hand, so it re-plans locally without a
  /// refetch.
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

  /// Player count reshapes the fetched pool: write the setting, let the store
  /// update trigger a refetch, and the new pool re-plans via didUpdateWidget.
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
          if (_lineup.filler != null && _lineup.main != null)
            _buildChangeover(context, GameNightSlot.main, _lineup.main!),
          _buildSlot(context, GameNightSlot.main, 'Main', 'The centrepiece', 1),
          _buildSlot(
            context,
            GameNightSlot.backup,
            'Backup',
            'If the mood shifts',
            2,
          ),
          if (_outroApplies && _includeOutro) ...[
            if (_lineup.main != null && _lineup.outro != null)
              _buildChangeover(context, GameNightSlot.outro, _lineup.outro!),
            _buildSlot(
              context,
              GameNightSlot.outro,
              'Outro',
              'Wind-down closer',
              3,
            ),
          ],
          _buildSpareSummary(context),
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
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w700,
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
              // A pinned slot gets a filled button so the locked state reads at
              // a glance; an unpinned one stays a plain outline.
              pinned
                  ? IconButton.filled(
                      tooltip: 'Unpin',
                      icon: const Icon(Icons.push_pin),
                      onPressed: () => _togglePin(slot),
                    )
                  : IconButton(
                      tooltip: 'Pin',
                      icon: const Icon(Icons.push_pin_outlined),
                      onPressed: () => _togglePin(slot),
                    ),
          ],
        ),
      ),
    );
  }

  /// Setup, teardown and breather reserved before [next], so the evening's gaps
  /// are visible rather than hidden inside the budget.
  Widget _buildChangeover(BuildContext context, GameNightSlot slot, Game next) {
    final minutes = GameNightPlanner.overheadFor(next);
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      key: ValueKey('game-night-changeover-${slot.name}'),
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hourglass_bottom, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '$minutes min to reset and set up',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  /// Time left after every played game and its changeover - the evening's
  /// breathing room.
  Widget _buildSpareSummary(BuildContext context) {
    if (_lineup.filler == null && _lineup.main == null) {
      return const SizedBox.shrink();
    }
    final spare = GameNightPlanner.spareMinutes(
      durationMinutes: _durationMinutes,
      filler: _lineup.filler,
      main: _lineup.main,
      outro: _lineup.outro,
    );
    final scheme = Theme.of(context).colorScheme;
    final label = spare == 0
        ? 'No spare time - the evening is full'
        : '${_formatGap(spare)} spare';
    return Padding(
      key: const ValueKey('game-night-spare'),
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.free_breakfast_outlined, size: 16, color: scheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: scheme.primary),
          ),
        ],
      ),
    );
  }

  /// Compact per-slot mechanic quick-pick, hidden until the pool carries
  /// mechanics so it degrades gracefully when the field is absent.
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

  /// Short spans read better in minutes; longer ones in hours.
  static String _formatGap(int minutes) {
    if (minutes < 60) return '$minutes min';
    return _formatDuration(minutes);
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

/// Filters the pool by whether the primary player has logged plays, so an
/// evening can favour familiar games or fresh ones to try.
enum _PlayFilter { all, unplayed, played }
