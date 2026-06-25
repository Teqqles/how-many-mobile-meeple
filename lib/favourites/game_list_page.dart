import 'package:flutter/material.dart';
import 'package:how_many_mobile_meeple/app_page.dart';
import 'package:how_many_mobile_meeple/components/platform_independent_image.dart';
import 'package:how_many_mobile_meeple/how_many_meeple_app_bar.dart';
import 'package:how_many_mobile_meeple/platform/router.dart' as r;
import 'favourite_game.dart';
import 'game_list_service.dart';

class GameListPage extends StatefulWidget {
  final String title;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptyDescription;
  final Future<GameListService> Function() serviceFactory;

  const GameListPage({
    super.key,
    required this.title,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptyDescription,
    required this.serviceFactory,
  });

  @override
  State<GameListPage> createState() => _GameListPageState();
}

class _GameListPageState extends State<GameListPage> with AppPage {
  GameListService? _service;

  @override
  void initState() {
    super.initState();
    _loadService();
  }

  Future<void> _loadService() async {
    final service = await widget.serviceFactory();
    service.addListener(_onChanged);
    setState(() => _service = service);
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
      appBar: HowManyMeepleAppBar(widget.title, context: context),
      endDrawer: pageDrawer(context),
      body: _service == null
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final games = _service!.games;
    if (games.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.emptyIcon,
                  size: 64, color: Theme.of(context).colorScheme.secondary),
              const SizedBox(height: 16),
              Text(
                widget.emptyTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                widget.emptyDescription,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: games.length,
      itemBuilder: (context, index) {
        final game = games[index];
        return Dismissible(
          key: ValueKey(game.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: Theme.of(context).colorScheme.error,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) => _service!.remove(game.id),
          child: _buildGameTile(context, game, index),
        );
      },
    );
  }

  Widget _buildGameTile(BuildContext context, FavouriteGame game, int index) {
    final isEven = index % 2 == 0;
    return Material(
      color: isEven
          ? Colors.transparent
          : Theme.of(context).colorScheme.primary.withAlpha(8),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            width: 44,
            height: 44,
            child: game.thumbnail != null
                ? PlatformIndependentImage(
                    imageUrl: game.thumbnail!,
                    fit: BoxFit.cover,
                  )
                : Container(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(Icons.casino,
                        size: 22,
                        color:
                            Theme.of(context).colorScheme.onPrimaryContainer),
                  ),
          ),
        ),
        title: Text(game.name),
        trailing: IconButton(
          icon: Icon(Icons.remove_circle_outline,
              color: Theme.of(context).colorScheme.error),
          tooltip: 'Remove',
          onPressed: () => _service!.remove(game.id),
        ),
        onTap: () => Navigator.of(context).pushNamed(
            '${r.Router.gameDetailRoute}/${game.name.replaceAll(' ', '+')}/${game.id}'),
      ),
    );
  }
}
