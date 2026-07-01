import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:how_many_mobile_meeple/components/quick_pick_sheet.dart';
import 'package:how_many_mobile_meeple/model/item.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/platform/router.dart' as r;
import 'package:how_many_mobile_meeple/app_common.dart';

class FeatureDrawer extends StatelessWidget {
  const FeatureDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppModel>(
      builder: (context, model, child) {
        final hasSources = model.items.itemList.isNotEmpty;
        final hasCollection = model.items.itemList
            .any((item) => item.itemType == ItemType.collection);

        return Drawer(
          child: SafeArea(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildHeader(context),
                _buildSectionTitle(context, 'Play'),
                _buildItem(
                  context,
                  icon: Icons.bolt,
                  label: 'Quick Pick',
                  enabled: hasSources,
                  onTap: () {
                    Navigator.of(context).pop();
                    QuickPickSheet.show(context);
                  },
                ),
                _buildItem(
                  context,
                  icon: Icons.casino,
                  label: 'Random Game',
                  enabled: hasSources,
                  onTap: () {
                    Navigator.of(context).pop();
                    final settings = r.Router.generateRouteSettings(
                        r.Router.randomRoute, model);
                    model.pageRefreshed = true;
                    Navigator.of(context).pushReplacementNamed(
                      settings.name!,
                      arguments: settings.arguments,
                    );
                  },
                ),
                _buildItem(
                  context,
                  icon: Icons.format_list_numbered,
                  label: 'View List',
                  enabled: hasSources,
                  onTap: () {
                    Navigator.of(context).pop();
                    final settings = r.Router.generateRouteSettings(
                        r.Router.listRoute, model);
                    model.pageRefreshed = true;
                    Navigator.of(context).pushReplacementNamed(
                      settings.name!,
                      arguments: settings.arguments,
                    );
                  },
                ),
                const Divider(),
                _buildSectionTitle(context, 'Discover'),
                _buildItem(
                  context,
                  icon: Icons.shelves,
                  label: 'Shelf of Shame',
                  enabled: hasCollection,
                  disabledMessage: 'Add a BGG collection first',
                  onTap: () {
                    Navigator.of(context).pop();
                    final username = model.primaryPlayer ?? '';
                    Navigator.of(context).pushNamed(
                        '${r.Router.shelfOfShameRoute}/${Uri.encodeComponent(username)}');
                  },
                ),
                const Divider(),
                _buildSectionTitle(context, 'My Games'),
                _buildItem(
                  context,
                  icon: Icons.favorite,
                  label: 'Favourites',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushNamed(r.Router.favouritesRoute);
                  },
                ),
                _buildItem(
                  context,
                  icon: Icons.history,
                  label: 'Play History',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushNamed(r.Router.playLogRoute);
                  },
                ),
                _buildItem(
                  context,
                  icon: Icons.visibility_off,
                  label: 'Ignored Games',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushNamed(r.Router.ignoredRoute);
                  },
                ),
                _buildItem(
                  context,
                  icon: Icons.newspaper,
                  label: 'Board Game News',
                  onTap: () {
                    Navigator.of(context).pop();
                    launchUrl(
                      Uri.parse('https://www.boardgamenews.co.uk/'),
                      mode: LaunchMode.externalApplication,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 80.0,
      child: DrawerHeader(
        padding: const EdgeInsets.only(left: 16),
        margin: EdgeInsets.zero,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            AppCommon.appTitle,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 12, bottom: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool enabled = true,
    String disabledMessage = 'Add a source first',
  }) {
    return ListTile(
      dense: true,
      leading: Icon(icon,
          size: 20,
          color: enabled
              ? null
              : Theme.of(context).colorScheme.onSurface.withAlpha(100)),
      title: Text(label,
          style: TextStyle(
            fontSize: 14,
            color: enabled
                ? null
                : Theme.of(context).colorScheme.onSurface.withAlpha(100),
          )),
      onTap: enabled
          ? onTap
          : () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(disabledMessage),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
    );
  }
}
