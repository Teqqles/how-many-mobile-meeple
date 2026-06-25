import 'package:flutter/material.dart';
import 'package:how_many_mobile_meeple/platform/router.dart' as r;
import 'package:provider/provider.dart';
import 'package:how_many_mobile_meeple/components/drawer_bgg_filter.dart';
import 'package:how_many_mobile_meeple/components/drawer_switch.dart';
import 'package:how_many_mobile_meeple/components/app_default_padding.dart';
import 'package:how_many_mobile_meeple/components/quick_pick_sheet.dart';
import 'package:how_many_mobile_meeple/favourites/ignored_games_service.dart';
import 'app_common.dart';
import 'components/component_factory.dart';
import 'model/model.dart';
import 'model/settings.dart';
import 'pwa/pwa_install_service.dart';
import 'theme_extensions.dart';
import 'tour_tips/tour_tip_service.dart';

mixin AppPage {
  static const String randomGameLabel = "Random Game";
  static Image randomGameButtonIcon = Image.asset('lib/images/dice.png');
  static const String randomGameHeroTag = "random-game";
  static const String listHeroTag = "list-games";

  final double _imageButtonSize = 42;

  Container drawerHeader(BuildContext context) => Container(
        height: 80.0,
        child: DrawerHeader(
          padding: const EdgeInsets.only(left: 8),
          margin: EdgeInsets.zero,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              BackButton(color: Theme.of(context).selectedRowColor),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  'Advanced Options',
                  style: TextStyle(color: Theme.of(context).selectedRowColor),
                ),
              )
            ],
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
      );

  List<Widget> staticFilters(AppModel model, BuildContext context) => [
        DrawerBggFilter(
            "Recommended Player Count Filter",
            model.settings
                .setting(Settings.filterUsingUserRecommendations.name),
            model,
            context,
            index: 0),
        DrawerBggFilter(
            "Include Expansions in Filter",
            model.settings.setting(Settings.filterIncludesExpansions.name),
            model,
            context,
            index: 1),
        DrawerBggFilter(
            "Show All Mechanics",
            model.settings.setting(Settings.filterUseAllMechanics.name),
            model,
            context,
            index: 2),
        _buildAdvancedModeToggle(model, context, index: 3),
        _buildTourTipsToggle(context, index: 4),
        _buildIgnoredGamesLink(context, index: 5),
      ];

  Widget _buildAdvancedModeToggle(AppModel model, BuildContext context,
      {int index = 0}) {
    final setting = model.settings.setting(Settings.preferAdvancedMode.name);
    final currentValue = setting.getBool();

    return Container(
      color: index % 2 == 0 ? Theme.of(context).highlightColor : Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          AppDefaultPadding(
            child: Text(
              "Always Use Advanced Mode",
              textAlign: TextAlign.left,
              style: TextStyle(fontSize: 13),
            ),
          ),
          DrawerSwitch(
            onChanged: (bool value) async {
              setting.value = value;
              setting.enabled = true;
              model.settings.updateSetting(setting);
              model.invalidateCache();
              await model.updateStore();
              Navigator.of(context).pop();
            },
            value: currentValue,
          )
        ],
      ),
    );
  }

  Widget _buildTourTipsToggle(BuildContext context, {int index = 0}) {
    return FutureBuilder<TourTipService>(
      future: TourTipService.instance(),
      builder: (context, snapshot) {
        final isEnabled = snapshot.hasData ? snapshot.data!.isEnabled : true;
        return Container(
          color:
              index % 2 == 0 ? Theme.of(context).highlightColor : Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              AppDefaultPadding(
                child: Text(
                  "Show Tour Tips",
                  textAlign: TextAlign.left,
                  style: TextStyle(fontSize: 13),
                ),
              ),
              DrawerSwitch(
                onChanged: (bool value) async {
                  final service = await TourTipService.instance();
                  await service.setEnabled(value);
                  Navigator.of(context).pop();
                },
                value: isEnabled,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIgnoredGamesLink(BuildContext context, {int index = 0}) {
    return FutureBuilder<IgnoredGamesService>(
      future: IgnoredGamesService.instance(),
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.games.length : 0;
        return Material(
          color:
              index % 2 == 0 ? Theme.of(context).highlightColor : Colors.white,
          child: ListTile(
            dense: true,
            leading: Icon(Icons.visibility_off,
                size: 20, color: Theme.of(context).colorScheme.secondary),
            title: Text(
              'Ignored Games${count > 0 ? ' ($count)' : ''}',
              style: const TextStyle(fontSize: 13),
            ),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(r.Router.ignoredRoute);
            },
          ),
        );
      },
    );
  }

  Future<List<Widget>> drawerFilters(
      BuildContext context, AppModel model) async {
    var drawerSettingsColumn =
        ComponentFactory.getDrawerSettingsColumn(AppCommon.savedSettings);
    final staticFiltersList = staticFilters(model, context);
    final allFilters = <Widget>[drawerHeader(context)] +
        staticFiltersList +
        await drawerSettingsColumn.drawerContent(
            context, model, staticFiltersList.length);
    if (PwaInstallService.isWeb && !PwaInstallService.isAlreadyInstalled) {
      allFilters.add(_buildInstallDrawerItem(context, allFilters.length));
    }
    return allFilters;
  }

  Widget _buildInstallDrawerItem(BuildContext context, int index) {
    final bgColor =
        index % 2 == 0 ? Theme.of(context).highlightColor : Colors.white;
    return Material(
      color: bgColor,
      child: ListTile(
        leading: const Icon(Icons.install_mobile),
        title: const Text(
          'Install on Home Screen',
          style: TextStyle(fontSize: 13),
        ),
        onTap: () {
          if (PwaInstallService.isInstallAvailable) {
            Navigator.of(context).pop();
            PwaInstallService.triggerInstall();
          } else {
            showDialog(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('Install on Home Screen'),
                content: const Text(
                  'To install, use your browser\'s install option:\n\n'
                  '• Chrome / Edge: tap the install icon (⊕) in the address bar\n'
                  '• Safari (iOS): tap Share → Add to Home Screen',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  void loadPage(BuildContext context, RouteSettings pageSettings) {
    AppModel.of(context, listen: false).pageRefreshed = true;
    Navigator.of(context).pushReplacementNamed(pageSettings.name!,
        arguments: pageSettings.arguments);
  }

  void startPage(BuildContext context) {
    AppModel.of(context, listen: false).refreshFromUrl();
  }

  Widget _floatingIconButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(40.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: IconButton(
          padding: const EdgeInsets.all(0),
          color: Theme.of(context).selectedRowColor,
          tooltip: tooltip,
          icon: Icon(icon, size: 36),
          onPressed: onPressed,
        ),
      ),
    );
  }

  Widget iconButtonGroup(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          _floatingIconButton(
            context,
            icon: Icons.format_list_numbered,
            tooltip: 'View List',
            onPressed: () {
              var listPageSettings = r.Router.generateRouteSettings(
                  r.Router.listRoute, AppModel.of(context, listen: false));
              loadPage(context, listPageSettings);
            },
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: _floatingIconButton(
              context,
              icon: Icons.bolt,
              tooltip: 'Quick Pick',
              onPressed: () => QuickPickSheet.show(context),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8),
            child: MaterialButton(
              onPressed: () {
                var randomPageSettings = r.Router.generateRouteSettings(
                    r.Router.randomRoute, AppModel.of(context, listen: false));
                loadPage(context, randomPageSettings);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(40.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 18, right: 12, top: 5, bottom: 5),
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                        height: _imageButtonSize,
                        width: _imageButtonSize,
                        child: randomGameButtonIcon,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 8, right: 8),
                        child: Text(
                          randomGameLabel,
                          style: TextStyle(
                              color: Theme.of(context).selectedRowColor,
                              fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );

  Widget pageDrawer(BuildContext context) {
    var staticDataComponentLength = 6;
    return Consumer<AppModel>(
      builder: (context, model, child) => Drawer(
        child: FutureBuilder(
          future: drawerFilters(context, model),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (!snapshot.hasData ||
                snapshot.data.length == staticDataComponentLength)
              return ListView(
                  children: <Widget>[drawerHeader(context)] +
                      staticFilters(model, context),
                  padding: EdgeInsets.zero);
            return ListView.builder(
              itemCount: snapshot.data.length,
              padding: EdgeInsets.zero,
              itemBuilder: (context, index) => snapshot.data[index],
            );
          },
        ),
      ),
    );
  }
}
