import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_common.dart';
import 'components/quick_pick_sheet.dart';
import 'model/model.dart';
import 'platform/router.dart' as r;
import 'save_dialog.dart';
import 'tour_tips/tour_tip_keys.dart';
import 'favourites/favourites_service.dart';

class HowManyMeepleAppBar extends AppBar {
  HowManyMeepleAppBar(String subtitle,
      {required BuildContext context,
      bool hasSaveDialog = false,
      bool isHomePage = false,
      AppModel? model})
      : super(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          leading: isHomePage
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Back',
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                          r.Router.homeRoute, (route) => false);
                    }
                  }),
          title: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(AppCommon.appTitle),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          actions: [
            IconButton(
              key: isHomePage && (ModalRoute.of(context)?.isCurrent ?? true)
                  ? TourTipKeys.appBarNewsButton
                  : null,
              icon: const Icon(Icons.newspaper),
              tooltip: 'Board Game News',
              onPressed: () => launchUrl(
                Uri.parse('https://www.boardgamenews.co.uk/'),
                mode: LaunchMode.externalApplication,
              ),
            ),
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.bolt),
                tooltip: 'Quick Pick',
                onPressed: () => QuickPickSheet.show(ctx),
              ),
            ),
            Builder(
              builder: (ctx) => FutureBuilder<FavouritesService>(
                future: FavouritesService.instance(),
                builder: (context, snapshot) => IconButton(
                  key: isHomePage && (ModalRoute.of(ctx)?.isCurrent ?? true)
                      ? TourTipKeys.appBarFavourites
                      : null,
                  icon: const Icon(Icons.favorite),
                  tooltip: 'Favourites',
                  onPressed: () =>
                      Navigator.of(ctx).pushNamed(r.Router.favouritesRoute),
                ),
              ),
            ),
            if (hasSaveDialog && model != null)
              IconButton(
                icon: const Icon(Icons.save),
                tooltip: 'Save Settings',
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => SaveDialog(model: model),
                ),
              ),
            Builder(
              builder: (ctx) => IconButton(
                key: isHomePage && (ModalRoute.of(ctx)?.isCurrent ?? true)
                    ? TourTipKeys.appBarSettingsButton
                    : null,
                icon: const Icon(Icons.settings),
                tooltip: 'Settings',
                onPressed: () => Scaffold.of(ctx).openEndDrawer(),
              ),
            ),
          ],
        );
}
