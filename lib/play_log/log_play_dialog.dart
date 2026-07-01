import 'package:flutter/material.dart';
import '../model/game.dart';
import 'play_date_format.dart';
import 'play_log_entry.dart';

/// Bottom sheet for recording or editing a play.
///
/// Provide [game] to log a new play, or [existing] to edit one. Everything
/// beyond the game is optional: the date defaults to now (or the existing
/// play's date) but can be changed, and the user may add players, mark winners
/// and enter scores. Returns the assembled [PlayLogEntry] on save (reusing the
/// existing id when editing), or null if dismissed without saving.
class LogPlayDialog extends StatefulWidget {
  final Game? game;
  final PlayLogEntry? existing;
  final List<String> suggestedPlayers;

  /// The user's own name (BGG primary player), pre-filled as a participant when
  /// logging a new play. Ignored when editing.
  final String? primaryPlayer;

  const LogPlayDialog({
    super.key,
    this.game,
    this.existing,
    this.suggestedPlayers = const [],
    this.primaryPlayer,
  }) : assert(game != null || existing != null,
            'Provide a game to log or an entry to edit');

  bool get isEditing => existing != null;

  int get gameId => existing?.gameId ?? game!.id;
  String get gameName => existing?.name ?? game!.name;
  String? get thumbnail => existing?.thumbnail ?? game?.thumbnail;

  static Future<PlayLogEntry?> show(
    BuildContext context, {
    Game? game,
    PlayLogEntry? existing,
    List<String> suggestedPlayers = const [],
    String? primaryPlayer,
  }) {
    return showModalBottomSheet<PlayLogEntry>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => LogPlayDialog(
        game: game,
        existing: existing,
        suggestedPlayers: suggestedPlayers,
        primaryPlayer: primaryPlayer,
      ),
    );
  }

  @override
  State<LogPlayDialog> createState() => _LogPlayDialogState();
}

class _LogPlayDialogState extends State<LogPlayDialog> {
  late DateTime _playedAt;
  final List<PlayerResult> _players = [];
  final TextEditingController _addPlayerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _playedAt = existing?.playedAt ?? DateTime.now();
    if (existing != null) {
      _players.addAll(existing.players.map((p) => p.copyWith()));
    } else {
      final self = widget.primaryPlayer?.trim();
      if (self != null && self.isNotEmpty) {
        _players.add(PlayerResult(name: self));
      }
    }
  }

  @override
  void dispose() {
    _addPlayerController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _playedAt,
      firstDate: DateTime(now.year - 20),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        // Preserve time-of-day so ordering stays stable for same-day plays.
        _playedAt = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _playedAt.hour,
          _playedAt.minute,
          _playedAt.second,
        );
      });
    }
  }

  void _addPlayer(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    if (_players.any((p) => p.name.toLowerCase() == trimmed.toLowerCase())) {
      return;
    }
    setState(() {
      _players.add(PlayerResult(name: trimmed));
      _addPlayerController.clear();
    });
  }

  void _removePlayer(int index) {
    setState(() => _players.removeAt(index));
  }

  void _toggleWinner(int index) {
    setState(() {
      _players[index] = _players[index].copyWith(won: !_players[index].won);
    });
  }

  void _setScore(int index, String value) {
    // Build directly rather than via copyWith so an empty field clears the
    // score (copyWith treats a null score as "leave unchanged").
    final current = _players[index];
    _players[index] = PlayerResult(
      name: current.name,
      won: current.won,
      score: int.tryParse(value.trim()),
    );
  }

  void _save() {
    final entry = PlayLogEntry(
      id: widget.existing?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      gameId: widget.gameId,
      name: widget.gameName,
      thumbnail: widget.thumbnail,
      playedAt: _playedAt,
      players: List.unmodifiable(_players),
    );
    Navigator.of(context).pop(entry);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unusedSuggestions = widget.suggestedPlayers
        .where((s) =>
            !_players.any((p) => p.name.toLowerCase() == s.toLowerCase()))
        .toList();

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.isEditing ? 'Edit play' : 'Log a play',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              widget.gameName,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildDateRow(theme),
            const SizedBox(height: 24),
            _buildPlayersSection(theme, unusedSuggestions),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: const Text(
                'Save play',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRow(ThemeData theme) {
    return Row(
      children: [
        Icon(Icons.event, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          'Date',
          style:
              theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: _pickDate,
          icon: const Icon(Icons.edit_calendar, size: 18),
          label: Text(PlayDateFormat.absolute(_playedAt)),
        ),
      ],
    );
  }

  Widget _buildPlayersSection(ThemeData theme, List<String> unusedSuggestions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.people, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Players',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Text(
              '(optional)',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._players.asMap().entries.map((e) => _buildPlayerRow(theme, e.key)),
        const SizedBox(height: 8),
        _buildAddPlayerField(theme),
        if (unusedSuggestions.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'You often play with',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: unusedSuggestions
                .map((name) => ActionChip(
                      avatar: const Icon(Icons.add, size: 16),
                      label: Text(name),
                      onPressed: () => _addPlayer(name),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildPlayerRow(ThemeData theme, int index) {
    final player = _players[index];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Tooltip(
            message: 'Winner',
            child: Checkbox(
              value: player.won,
              onChanged: (_) => _toggleWinner(index),
            ),
          ),
          Icon(
            Icons.emoji_events,
            size: 18,
            color: player.won
                ? Colors.amber.shade700
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(player.name)),
          SizedBox(
            width: 72,
            child: TextFormField(
              key: ValueKey('score_${player.name}'),
              initialValue: player.score?.toString(),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Score',
                isDense: true,
              ),
              onChanged: (value) => _setScore(index, value),
            ),
          ),
          IconButton(
            tooltip: 'Remove player',
            icon: Icon(Icons.close, color: theme.colorScheme.error),
            onPressed: () => _removePlayer(index),
          ),
        ],
      ),
    );
  }

  Widget _buildAddPlayerField(ThemeData theme) {
    return TextField(
      controller: _addPlayerController,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        hintText: 'Add a player',
        prefixIcon: const Icon(Icons.person_add_alt),
        suffixIcon: IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => _addPlayer(_addPlayerController.text),
        ),
      ),
      onSubmitted: _addPlayer,
    );
  }
}
