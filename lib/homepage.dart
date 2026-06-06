import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:how_many_mobile_meeple/components/board_game_item_input_widget.dart';
import 'package:how_many_mobile_meeple/components/board_game_item_list_widget.dart';
import 'package:how_many_mobile_meeple/components/complexity_filter_widget.dart';
import 'package:how_many_mobile_meeple/components/mechanic_filter_widget.dart';
import 'package:how_many_mobile_meeple/components/player_filter_widget.dart';
import 'package:how_many_mobile_meeple/components/rating_filter_widget.dart';
import 'package:how_many_mobile_meeple/components/time_filter_widget.dart';
import 'package:how_many_mobile_meeple/platform/web_or_tablet/web_version_info.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:how_many_mobile_meeple/components/app_default_padding.dart';
import 'app_page.dart';
import 'package:how_many_mobile_meeple/components/disclaimer_text.dart';
import 'app_common.dart';
import 'components/empty_widget.dart';
import 'how_many_meeple_app_bar.dart';
import 'package:how_many_mobile_meeple/model/model.dart';

class HomePage extends StatelessWidget with AppPage {
  static final String route = "Home-page";

  @override
  Widget build(BuildContext context) {
    final model = AppModel.of(context, listen: false);
    if (!model.hasLoadedPersistedData) {
      model.loadStoredData();
      model.refreshFromUrl();
    }
    return Scaffold(
        appBar: HowManyMeepleAppBar(AppCommon.optionsPageTitle,
            hasSaveDialog: true,
            isHomePage: true,
            model: model,
            context: context),
        drawer: pageDrawer(context),
        bottomNavigationBar: Container(
          color: Theme.of(context).highlightColor,
          child: AppDefaultPadding(
            child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  FutureBuilder<Widget>(
                      future: footerDisplay(context),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) return snapshot.data!;
                        return EmptyWidget();
                      })
                ]),
          ),
        ),
        body: const SingleChildScrollView(
            child: Column(children: <Widget>[
          BoardGameItemInputWidget(),
          BoardGameItemListWidget(),
          TimeFilterWidget(),
          PlayerFilterWidget(),
          ComplexityFilterWidget(),
          RatingFilterWidget(),
          MechanicFilterWidget(),
        ])),
        persistentFooterButtons: [iconButtonGroup(context)]);
  }

  Future<String> getAppVersion() async {
    if (kIsWeb) {
      return WebVersionInfo.name;
    } else {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    }
  }

  Future<Widget> footerDisplay(BuildContext context) async {
    var version = await getAppVersion();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: BGGAttribution(),
        ),
        DisclaimerText("(v:$version)", context)
      ],
    );
  }
}
