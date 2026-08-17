import 'package:flutter/material.dart';
import 'package:how_many_mobile_meeple/components/platform_independent_image.dart';
import 'package:how_many_mobile_meeple/model/game.dart';
import 'package:how_many_mobile_meeple/model/game_night.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';

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

  final Map<GameNightSlot, Game> _pinned = {};
  GameNightLineup _lineup = const GameNightLineup();

  int get _durationMinutes => widget.model.settings
      .setting(Settings.gameNightDurationMinutes.name)
      .getInt();

  @override
  void initState() {
    super.initState();
    _regenerate();
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
        pool: widget.pool,
        durationMinutes: _durationMinutes,
        pinned: Map.of(_pinned),
      );
    });
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
          const SizedBox(height: 20),
          _buildSlot(context, GameNightSlot.filler, 'Filler', 'Warm-up'),
          _buildSlot(context, GameNightSlot.main, 'Main', 'The centrepiece'),
          _buildSlot(
            context,
            GameNightSlot.backup,
            'Backup',
            'If the mood shifts',
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            key: const ValueKey('game-night-regenerate'),
            onPressed: _regenerate,
            icon: const Icon(Icons.casino),
            label: const Text('Regenerate'),
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

  Widget _buildSlot(
    BuildContext context,
    GameNightSlot slot,
    String title,
    String subtitle,
  ) {
    final game = _lineup.slot(slot);
    final pinned = _pinned.containsKey(slot);
    return Card(
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
