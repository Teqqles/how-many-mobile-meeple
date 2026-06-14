import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:how_many_mobile_meeple/screen_tools.dart';

import 'package:how_many_mobile_meeple/components/app_default_padding.dart';
import 'load_games.dart';
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
                color: Theme.of(context).colorScheme.secondary,
                size: spinnerSize),
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
/// A new fetch is only started when the cache transitions to stale AND
/// no fetch is already in progress.
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
  Future<Games>? _future;
  bool _fetching = false;

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
    // Only start a new fetch when the cache has become stale and no fetch is running.
    if (widget.model.bggCache.isStale() && !_fetching) {
      setState(_startFetch);
    }
  }

  void _startFetch() {
    _fetching = true;
    _future = LoadGames.fetchGames(
        widget.model.settings, widget.model.items.itemList);
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
    return FutureBuilder<Games>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data!.games.isEmpty) {
            return widget.pageErrors(
                context, NetworkWidget.pageErrorNoGamesAvailable);
          }
          widget.model.replaceCache(snapshot.data!);
          return widget.displayWidgetFn(context, widget.model);
        } else if (snapshot.hasError) {
          return widget.pageErrors(
              context, NetworkWidget.pageErrorOneOrMoreItemsInvalid);
        }
        return widget.pageFrameOutline(context, widget.loadingSpinner(context));
      },
    );
  }
}
