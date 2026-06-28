import 'package:flutter/material.dart';

import 'app_common.dart';
import 'model/model.dart';
import 'platform/router.dart' as r;
import 'save_dialog.dart';
import 'tour_tips/tour_tip_keys.dart';

class HowManyMeepleAppBar extends AppBar {
  HowManyMeepleAppBar(String subtitle,
      {required BuildContext context,
      bool hasSaveDialog = false,
      bool isHomePage = false,
      AppModel? model})
      : super(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          leading: Builder(
            builder: (ctx) => isHomePage
                ? IconButton(
                    icon: const Icon(Icons.menu),
                    tooltip: 'Menu',
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.menu),
                        tooltip: 'Menu',
                        onPressed: () => Scaffold.of(ctx).openDrawer(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        tooltip: 'Back',
                        onPressed: () {
                          if (Navigator.of(ctx).canPop()) {
                            Navigator.of(ctx).pop();
                          } else {
                            Navigator.of(ctx).pushNamedAndRemoveUntil(
                                r.Router.homeRoute, (route) => false);
                          }
                        },
                      ),
                    ],
                  ),
          ),
          leadingWidth: isHomePage ? null : 96,
          titleSpacing: isHomePage ? null : 0,
          title: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(AppCommon.appTitle),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          actions: [
            Row(
              key: isHomePage && (ModalRoute.of(context)?.isCurrent ?? true)
                  ? TourTipKeys.appBarActions
                  : null,
              mainAxisSize: MainAxisSize.min,
              children: [
                Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(Icons.favorite, size: 20),
                    tooltip: 'Favourites',
                    visualDensity: VisualDensity.compact,
                    onPressed: () =>
                        Navigator.of(ctx).pushNamed(r.Router.favouritesRoute),
                  ),
                ),
                if (hasSaveDialog && model != null)
                  IconButton(
                    icon: const Icon(Icons.save, size: 20),
                    tooltip: 'Save Settings',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => showDialog(
                      context: context,
                      builder: (context) => SaveDialog(model: model),
                    ),
                  ),
                Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(Icons.settings, size: 20),
                    tooltip: 'Settings',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Scaffold.of(ctx).openEndDrawer(),
                  ),
                ),
              ],
            ),
          ],
        );
}
