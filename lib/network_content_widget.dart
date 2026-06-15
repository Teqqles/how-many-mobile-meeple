import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:how_many_mobile_meeple/screen_tools.dart';

import 'package:how_many_mobile_meeple/components/app_default_padding.dart';
import 'load_games.dart';
import 'package:how_many_mobile_meeple/model/game_request.dart';
import 'package:how_many_mobile_meeple/model/model.dart';

import 'model/games.dart';

abstract class NetworkWidget extends StatelessWidget with ScreenTools {
  static const String speedDisclaimer =
      "this may take some time as board game geek is slow";
  static const String pageErrorNoItemsSupplied =
      "You must provide at least one geeklist or user collection";
  static const String pageErrorOneOrMoreItemsInvalid =
      "One or more of your geeklists or user collections cannot be loaded";
  static const String pageErrorNoGamesAvailable =
      "Your filters have eliminated all games, try relaxing them to be able to select a game";

  static const String findingGames = "Finding games to play";

  Widget pageErrors(BuildContext context, String error) {
    final iconSize = getScreenWidthPercentageInPixels(
            context, ScreenTools.fiftyPercentScreen)
        .clamp(0.0, 200.0);

    return Center(
      child: Container(
        width: getScreenWidthPercentageInPixels(
            context, ScreenTools.fiftyPercentScreen),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppDefaultPadding(
                child: Icon(Icons.error,
                    color: Theme.of(context).colorScheme.error, size: iconSize),
              ),
              Text(
                error,
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ]),
      ),
    );
  }

  Widget loadingSpinner(BuildContext context) {
    final spinnerSize = getScreenWidthPercentageInPixels(
            context, ScreenTools.fiftyPercentScreen)
        .clamp(0.0, 200.0);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppDefaultPadding(
            child: SpinKitCubeGrid(
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
          ),
          Text(findingGames, style: TextStyle(fontWeight: FontWeight.bold)),
          Text(
            speedDisclaimer,
            style: TextStyle(fontSize: 12),
          )
        ],
      ),
    );
  }

  Widget loadNetworkContent(
      Widget displayWidgetFn(BuildContext context, AppModel model)) {
    return Consumer<AppModel>(builder: (context, model, child) {
      if (model.items.isEmpty) {
        return pageErrors(context, pageErrorNoItemsSupplied);
      }
      return _GameFetcher(
        model: model,
        pageErrors: pageErrors,
        loadingSpinner: loadingSpinner,
        pageFrameOutline: pageFrameOutline,
        displayWidgetFn: displayWidgetFn,
      );
    });
  }
}

/// Stateful widget that owns the fetch Future so that model notifications
/// (notifyListeners) do not abandon an in-flight request and restart it.
/// A new fetch is started when the cache is stale and no fetch is in progress,
/// or when the request (items + headers) has changed from the one in-flight.
class _GameFetcher extends StatefulWidget {
  final AppModel model;
  final Widget Function(BuildContext, String) pageErrors;
  final Widget Function(BuildContext) loadingSpinner;
  final Widget Function(BuildContext, Widget) pageFrameOutline;
  final Widget Function(BuildContext, AppModel) displayWidgetFn;

  const _GameFetcher({
    required this.model,
    required this.pageErrors,
    required this.loadingSpinner,
    required this.pageFrameOutline,
    required this.displayWidgetFn,
  });

  @override
  State<_GameFetcher> createState() => _GameFetcherState();
}

class _GameFetcherState extends State<_GameFetcher> {
  Future<(Games, GameRequest)>? _future;
  bool _fetching = false;
  GameRequest? _inflightRequest;

  @override
  void initState() {
    super.initState();
    if (widget.model.bggCache.isStale()) {
      _startFetch();
    }
  }

  @override
  void didUpdateWidget(_GameFetcher old) {
    super.didUpdateWidget(old);
    final currentRequest = widget.model.buildRequest();
    final cacheIsStale = widget.model.bggCache.isStale();
    final requestChanged =
        _inflightRequest != null && _inflightRequest != currentRequest;

    if ((cacheIsStale && !_fetching) || requestChanged) {
      setState(_startFetch);
    }
  }

  void _startFetch() {
    final request = widget.model.buildRequest();
    _fetching = true;
    _inflightRequest = request;
    _future = LoadGames.fetchGames(request).then((games) => (games, request));
    _future!.then(
      (_) {
        if (mounted) setState(() => _fetching = false);
      },
      onError: (_) {
        if (mounted) setState(() => _fetching = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.model.bggCache.isStale()) {
      return widget.displayWidgetFn(context, widget.model);
    }
    return FutureBuilder<(Games, GameRequest)>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final (games, request) = snapshot.data!;
          if (games.games.isEmpty) {
            return widget.pageErrors(
                context, NetworkWidget.pageErrorNoGamesAvailable);
          }
          widget.model.replaceCache(games, request);
          if (!widget.model.bggCache.isStale()) {
            return widget.displayWidgetFn(context, widget.model);
          }
          return widget.pageFrameOutline(
              context, widget.loadingSpinner(context));
        } else if (snapshot.hasError) {
          return widget.pageErrors(
              context, NetworkWidget.pageErrorOneOrMoreItemsInvalid);
        }
        return widget.pageFrameOutline(context, widget.loadingSpinner(context));
      },
    );
  }
}
