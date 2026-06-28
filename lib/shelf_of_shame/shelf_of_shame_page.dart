import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:how_many_mobile_meeple/api/http_retry_client.dart';
import 'package:how_many_mobile_meeple/app_common.dart';
import 'package:how_many_mobile_meeple/app_page.dart';
import 'package:how_many_mobile_meeple/components/feature_drawer.dart';
import 'package:how_many_mobile_meeple/components/loading_fun_facts.dart';
import 'package:how_many_mobile_meeple/components/platform_independent_image.dart';
import 'package:how_many_mobile_meeple/how_many_meeple_app_bar.dart';
import 'package:how_many_mobile_meeple/model/game.dart';
import 'package:how_many_mobile_meeple/model/games.dart';
import 'package:how_many_mobile_meeple/model/item.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';
import 'package:how_many_mobile_meeple/network_content_widget.dart';
import 'package:how_many_mobile_meeple/platform/router.dart' as r;
import 'package:how_many_mobile_meeple/screen_tools.dart';

class ShelfOfShamePage extends StatefulWidget {
  final String? username;

  const ShelfOfShamePage({super.key, this.username});

  @override
  State<ShelfOfShamePage> createState() => _ShelfOfShamePageState();
}

class _ShelfOfShamePageState extends State<ShelfOfShamePage>
    with AppPage, ScreenTools {
  Games? _fullCollection;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String? get _targetUsername {
    return widget.username ?? AppModel.of(context, listen: false).primaryPlayer;
  }

  Future<void> _loadData() async {
    final model = AppModel.of(context, listen: false);
    final username = _targetUsername;
    if (username == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      if (!model.playsLoaded) {
        await model.loadPlays();
      }
      final games = await _fetchFullCollection(username);
      if (mounted) {
        setState(() {
          _fullCollection = games;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load collection';
          _loading = false;
        });
      }
    }
  }

  Future<Games> _fetchFullCollection(String username) async {
    final url = Uri.parse(
        '${AppCommon.boardGameGeekProxyUrl}/collection/${Uri.encodeComponent(username)}');
    final headers = {
      Settings.fieldsToReturnFromApi.header!:
          Settings.fieldsToReturnFromApi.value.toString(),
    };
    final response = await HttpRetryClient.getWithRetry(url, headers: headers);
    if (response.statusCode == 200) {
      return Games.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load collection');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HowManyMeepleAppBar('Shelf of Shame', context: context),
      drawer: const FeatureDrawer(),
      endDrawer: pageDrawer(context),
      body: Consumer<AppModel>(
        builder: (context, model, child) {
          final hasCollection = model.items.itemList
              .any((item) => item.itemType == ItemType.collection);
          if (!hasCollection && widget.username == null) {
            return _buildNoCollection(context);
          }
          if (_targetUsername == null) {
            return _buildNoPrimaryPlayer(context);
          }
          if (_loading) {
            return _buildLoadingScreen(context);
          }
          if (_error != null) {
            return Center(child: Text(_error!));
          }
          return _buildBody(context, model);
        },
      ),
    );
  }

  Widget _buildNoCollection(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shelves,
                size: 64, color: Theme.of(context).colorScheme.secondary),
            const SizedBox(height: 16),
            Text(
              'No collection added',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Shelf of Shame requires a BGG collection. Add your BGG username in Step 1 to get started.',
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

  Widget _buildNoPrimaryPlayer(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shelves,
                size: 64, color: Theme.of(context).colorScheme.secondary),
            const SizedBox(height: 16),
            Text(
              'No primary player set',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Add a BGG collection in Step 1 and tap the crown icon to designate your primary player for play tracking.',
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

  Widget _buildLoadingScreen(BuildContext context) {
    final spinnerSize = getScreenWidthPercentageInPixels(
            context, ScreenTools.fiftyPercentScreen)
        .clamp(0.0, 200.0);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SpinKitCubeGrid(
              size: spinnerSize,
              itemBuilder: (context, index) {
                final isLight = (index ~/ 3 + index % 3) % 2 == 0;
                final color = Theme.of(context).colorScheme.secondary;
                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: isLight ? color : color.withValues(alpha: 0.5),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Text(NetworkWidget.findingGames,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(
              NetworkWidget.speedDisclaimer,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            const LoadingFunFacts(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppModel model) {
    final allGames = _fullCollection!;
    final unplayedGames = allGames.gamesByName.values
        .where((game) => model.isUnplayed(game.id))
        .toList();

    if (unplayedGames.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.celebration,
                  size: 64, color: Theme.of(context).colorScheme.secondary),
              const SizedBox(height: 16),
              Text(
                'No shame here!',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'All your games have been played at least once. Well done!',
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

    return Column(
      children: [
        _buildCollectionBanner(context, model, unplayedGames.length),
        Expanded(
          child: ListView.builder(
            itemCount: unplayedGames.length + 1,
            itemBuilder: (context, index) {
              if (index == unplayedGames.length) {
                return _buildBgStatsPlug(context);
              }
              return _buildGameTile(context, unplayedGames[index], index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCollectionBanner(
      BuildContext context, AppModel model, int count) {
    final displayName = _targetUsername ?? model.primaryPlayer ?? '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Theme.of(context).colorScheme.primaryContainer.withAlpha(120),
      child: Row(
        children: [
          FaIcon(FontAwesomeIcons.crown,
              size: 14, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$displayName\'s collection • $count unplayed',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameTile(BuildContext context, Game game, int index) {
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
        subtitle: Text(
          '${game.minPlayers}-${game.maxPlayers} players',
          style: TextStyle(
              fontSize: 12, color: Theme.of(context).colorScheme.secondary),
        ),
        onTap: () => Navigator.of(context).pushNamed(
            '${r.Router.gameDetailRoute}/${game.name.replaceAll(' ', '+')}/${game.id}'),
      ),
    );
  }

  Widget _buildBgStatsPlug(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.bar_chart,
                  size: 24, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Track your plays',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Log plays with BG Stats to keep your shelf of shame up to date',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.open_in_new),
                onPressed: () => launchUrl(
                  Uri.parse('https://www.bgstatsapp.com/'),
                  mode: LaunchMode.externalApplication,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
