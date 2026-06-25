import 'package:flutter/material.dart';
import 'package:how_many_mobile_meeple/components/app_default_padding.dart';
import 'package:how_many_mobile_meeple/favourites/favourite_game.dart';
import 'package:how_many_mobile_meeple/favourites/favourites_service.dart';
import 'package:how_many_mobile_meeple/favourites/ignored_games_service.dart';
import 'package:how_many_mobile_meeple/platform/router.dart' as r;
import '../../app_page.dart';
import '../../app_common.dart';
import 'package:how_many_mobile_meeple/components/heading_text.dart';
import '../../how_many_meeple_app_bar.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import '../../model/game.dart';
import '../../model/games.dart';
import '../../network_content_widget.dart';
import '../../screen_tools.dart';
import 'package:how_many_mobile_meeple/components/platform_independent_image.dart';
import 'package:how_many_mobile_meeple/components/rating_badge.dart';

class EnhancedListGamesDisplayPage extends NetworkWidget with AppPage {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar:
            HowManyMeepleAppBar(AppCommon.listGamesPageTitle, context: context),
        endDrawer: pageDrawer(context),
        persistentFooterButtons: [iconButtonGroup(context)],
        body: Container(child: loadNetworkContent(displayGame)));
  }

  Widget displayGame(BuildContext context, AppModel model) {
    return FutureBuilder(
      future: Future.wait([
        FavouritesService.instance(),
        IgnoredGamesService.instance(),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final favService = snapshot.data![0] as FavouritesService;
        final ignoreService = snapshot.data![1] as IgnoredGamesService;
        return _GameListBody(
          model: model,
          favouritesService: favService,
          ignoredService: ignoreService,
        );
      },
    );
  }
}

class _GameListBody extends StatefulWidget {
  final AppModel model;
  final FavouritesService favouritesService;
  final IgnoredGamesService ignoredService;

  const _GameListBody({
    required this.model,
    required this.favouritesService,
    required this.ignoredService,
  });

  @override
  State<_GameListBody> createState() => _GameListBodyState();
}

class _GameListBodyState extends State<_GameListBody> with ScreenTools {
  bool _showIgnored = false;

  @override
  void initState() {
    super.initState();
    widget.favouritesService.addListener(_rebuild);
    widget.ignoredService.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.favouritesService.removeListener(_rebuild);
    widget.ignoredService.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final model = widget.model;
    var allGames = model.bggCache.games
        .getGamesBy(field: model.sortGameField, order: model.sortDirection);
    final games = _showIgnored
        ? allGames
        : allGames.where((g) => !widget.ignoredService.contains(g.id)).toList();

    if (games.isEmpty) {
      return _buildExhaustedState(context);
    }

    return Column(
      children: [
        _buildHeader(context, model),
        Expanded(
          child: ListView.builder(
            itemCount: games.length,
            itemBuilder: (context, index) =>
                _buildDismissibleRow(context, games[index], index),
          ),
        ),
      ],
    );
  }

  Widget _buildExhaustedState(BuildContext context) {
    final hasIgnored = widget.ignoredService.games.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.format_list_numbered,
                size: 64, color: Theme.of(context).colorScheme.secondary),
            const SizedBox(height: 16),
            Text(
              'All games are currently hidden',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (hasIgnored) ...[
              const SizedBox(height: 12),
              Text(
                'Want to try again including your ignored games?',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => setState(() => _showIgnored = true),
                icon: const Icon(Icons.refresh),
                label: const Text('Include ignored games'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppModel model) {
    return Container(
      decoration: BoxDecoration(
        border:
            Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 56),
          Expanded(
            flex: 4,
            child: _sortButton(context, model, 'Name', SortableGameField.name,
                alignment: Alignment.centerLeft),
          ),
          SizedBox(
            width: 80,
            child: _sortButton(
                context, model, null, SortableGameField.maxPlaytime,
                icon: Icons.timer),
          ),
          SizedBox(
            width: 60,
            child: _sortButton(context, model, null, SortableGameField.weight,
                icon: Icons.fitness_center),
          ),
          SizedBox(
            width: 60,
            child: _sortButton(context, model, null, SortableGameField.rating,
                icon: Icons.star),
          ),
        ],
      ),
    );
  }

  Widget _sortButton(BuildContext context, AppModel model, String? label,
      SortableGameField field,
      {IconData? icon, Alignment alignment = Alignment.centerRight}) {
    return TextButton(
      style: TextButton.styleFrom(padding: EdgeInsets.zero),
      onPressed: () {
        model.toggleSortDirection();
        model.sortGameField = field;
        model.refreshState();
      },
      child: Container(
        alignment: alignment,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (label != null) HeadingText(label, context),
            if (icon != null)
              Icon(icon,
                  size: 18, color: Theme.of(context).colorScheme.secondary),
            if (model.sortGameField == field)
              Icon(
                model.sortDirection == SortOrder.Asc
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
                size: 12,
                color: Theme.of(context).colorScheme.secondary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDismissibleRow(BuildContext context, Game game, int index) {
    final isFav = widget.favouritesService.contains(game.id);
    final favGame =
        FavouriteGame(id: game.id, name: game.name, thumbnail: game.thumbnail);

    return Dismissible(
      key: ValueKey(game.id),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        color: Colors.amber.shade700,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isFav ? Icons.heart_broken : Icons.favorite,
                color: Colors.white),
            const SizedBox(width: 8),
            Text(isFav ? 'Unfavourite' : 'Favourite',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Theme.of(context).colorScheme.error,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Ignore',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            SizedBox(width: 8),
            Icon(Icons.visibility_off, color: Colors.white),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          widget.favouritesService.toggle(favGame);
          return false;
        } else {
          widget.ignoredService.toggle(favGame);
          return true;
        }
      },
      child: _buildRow(context, game, index, isFav),
    );
  }

  Widget _buildRow(BuildContext context, Game game, int index, bool isFav) {
    final isEven = index % 2 == 0;
    final isWide = isWideScreen(context);
    final favGame =
        FavouriteGame(id: game.id, name: game.name, thumbnail: game.thumbnail);

    return Container(
      decoration: BoxDecoration(
        color: isEven
            ? Colors.transparent
            : Theme.of(context).colorScheme.primary.withAlpha(8),
        border:
            Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: ClipRRect(
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
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer),
                      ),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: AppDefaultPadding(
              child: InkWell(
                onTap: () => Navigator.of(context).pushNamed(
                    '${r.Router.gameDetailRoute}/${game.name.replaceAll(' ', '+')}/${game.id}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        if (isFav)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(Icons.favorite,
                                size: 14, color: Colors.amber.shade700),
                          ),
                        Flexible(
                          child: Text(game.name,
                              style: const TextStyle(
                                decoration: TextDecoration.underline,
                              )),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people,
                            size: 12,
                            color: Theme.of(context).colorScheme.secondary),
                        const SizedBox(width: 3),
                        Text(
                          game.minPlayers == game.maxPlayers
                              ? '${game.minPlayers} players'
                              : '${game.minPlayers}-${game.maxPlayers} players',
                          style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.secondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: AppDefaultPadding(
              child: Container(
                alignment: Alignment.centerRight,
                child: Text(AppCommon.minutesToTime(game.maxPlaytime)),
              ),
            ),
          ),
          SizedBox(
            width: 60,
            child: AppDefaultPadding(
              child: Container(
                alignment: Alignment.centerRight,
                child: Text(game.averageWeight.toStringAsFixed(2)),
              ),
            ),
          ),
          SizedBox(
            width: 60,
            child: Center(
              child: MiniRatingBadge(rating: game.averageRating, size: 38),
            ),
          ),
          if (isWide) ...[
            IconButton(
              icon: Icon(
                isFav ? Icons.favorite : Icons.favorite_border,
                color: isFav ? Colors.amber.shade700 : null,
              ),
              tooltip: isFav ? 'Unfavourite' : 'Favourite',
              onPressed: () => widget.favouritesService.toggle(favGame),
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              icon: const Icon(Icons.visibility_off),
              tooltip: 'Ignore',
              onPressed: () => widget.ignoredService.toggle(favGame),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ],
      ),
    );
  }
}
