import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'favourite_game.dart';
import 'favourites_service.dart';
import 'ignored_games_service.dart';
import '../model/game.dart';

class GameActionButtons extends StatefulWidget {
  final Game game;

  const GameActionButtons({super.key, required this.game});

  @override
  State<GameActionButtons> createState() => _GameActionButtonsState();
}

class _GameActionButtonsState extends State<GameActionButtons> {
  FavouritesService? _favService;
  IgnoredGamesService? _ignoreService;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    final fav = await FavouritesService.instance();
    final ignore = await IgnoredGamesService.instance();
    fav.addListener(_rebuild);
    ignore.addListener(_rebuild);
    if (mounted) {
      setState(() {
        _favService = fav;
        _ignoreService = ignore;
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
    if (_favService == null || _ignoreService == null) {
      return const SizedBox.shrink();
    }

    final game = widget.game;
    final favGame =
        FavouriteGame(id: game.id, name: game.name, thumbnail: game.thumbnail);
    final isFav = _favService!.contains(game.id);
    final isIgnored = _ignoreService!.contains(game.id);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: () => _favService!.toggle(favGame),
            icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
            label: Text(isFav ? 'Unfavourite' : 'Favourite'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isFav
                  ? Colors.amber.shade700
                  : Theme.of(context).colorScheme.secondary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () {
              _ignoreService!.toggle(favGame);
              if (!isIgnored && Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
            icon: Icon(isIgnored ? Icons.visibility : Icons.visibility_off),
            label: Text(isIgnored ? 'Unignore' : 'Ignore'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isIgnored
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => _share(context, game),
            icon: const Icon(Icons.share),
            label: const Text('Share'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
          ),
        ],
      ),
    );
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
