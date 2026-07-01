// coverage:ignore-file
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'favourite_game.dart';
import 'favourites_service.dart';
import 'ignored_games_service.dart';
import '../model/game.dart';
import '../model/model.dart';
import '../play_log/log_play_dialog.dart';
import '../play_log/play_log_service.dart';
import '../services/service_locator.dart';

class GameActionButtons extends StatefulWidget {
  final Game game;

  const GameActionButtons({super.key, required this.game});

  @override
  State<GameActionButtons> createState() => _GameActionButtonsState();
}

class _GameActionButtonsState extends State<GameActionButtons> {
  FavouritesService? _favService;
  IgnoredGamesService? _ignoreService;
  PlayLogService? _playLogService;
  bool _servicesLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_servicesLoading && _favService == null) {
      _servicesLoading = true;
      _loadServices();
    }
  }

  Future<void> _loadServices() async {
    final services = context.gameServices;
    final fav = await services.favourites();
    final ignore = await services.ignored();
    final playLog = await services.playLog();
    fav.addListener(_rebuild);
    ignore.addListener(_rebuild);
    if (mounted) {
      setState(() {
        _favService = fav;
        _ignoreService = ignore;
        _playLogService = playLog;
      });
    }
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _favService?.removeListener(_rebuild);
    _ignoreService?.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_favService == null ||
        _ignoreService == null ||
        _playLogService == null) {
      return const SizedBox.shrink();
    }

    final game = widget.game;
    final favGame =
        FavouriteGame(id: game.id, name: game.name, thumbnail: game.thumbnail);
    final isFav = _favService!.contains(game.id);
    final isIgnored = _ignoreService!.contains(game.id);
    final compact = MediaQuery.of(context).size.width < 480;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          _actionButton(
            context,
            onPressed: () => _logPlay(context, game),
            icon: const Icon(Icons.check_circle_outline),
            label: 'Played it',
            compact: compact,
            backgroundColor: Colors.green.shade700,
          ),
          _actionButton(
            context,
            onPressed: () => _favService!.toggle(favGame),
            icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
            label: isFav ? 'Unfavourite' : 'Favourite',
            compact: compact,
            backgroundColor: isFav
                ? Colors.amber.shade700
                : Theme.of(context).colorScheme.secondary,
          ),
          _actionButton(
            context,
            onPressed: () {
              _ignoreService!.toggle(favGame);
              if (!isIgnored && Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
            icon: Icon(isIgnored ? Icons.visibility : Icons.visibility_off),
            label: isIgnored ? 'Unignore' : 'Ignore',
            compact: compact,
            backgroundColor: isIgnored
                ? Theme.of(context).colorScheme.secondary
                : Theme.of(context).colorScheme.error,
          ),
          _actionButton(
            context,
            onPressed: () => _share(context, game),
            icon: const Icon(Icons.share),
            label: 'Share',
            compact: compact,
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
    BuildContext context, {
    required VoidCallback onPressed,
    required Widget icon,
    required String label,
    required bool compact,
    required Color backgroundColor,
  }) {
    final style = ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    );

    if (compact) {
      return IconButton(
        onPressed: onPressed,
        icon: icon,
        tooltip: label,
        style: IconButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: icon,
      label: Text(label),
      style: style,
    );
  }

  void _logPlay(BuildContext context, Game game) async {
    final service = _playLogService;
    if (service == null) return;
    final entry = await LogPlayDialog.show(
      context,
      game: game,
      suggestedPlayers: service.frequentPlayers(),
      primaryPlayer: AppModel.of(context, listen: false).primaryPlayerName,
    );
    if (entry == null) return;
    service.logPlay(entry);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logged a play of ${game.name}')),
      );
    }
  }

  void _share(BuildContext context, Game game) async {
    final baseUri = Uri.base.removeFragment();
    final uri = baseUri.replace(
        fragment: '/game/${game.name.replaceAll(' ', '+')}/${game.id}');
    final url = uri.toString();
    try {
      await SharePlus.instance.share(
        ShareParams(title: '${game.name} on How Many Meeple', uri: uri),
      );
    } catch (_) {
      _showCopyLinkDialog(context, url);
    }
  }

  void _showCopyLinkDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Share Link'),
        content: SelectableText(url),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: url));
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Link copied to clipboard')),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy Link'),
          ),
        ],
      ),
    );
  }
}
