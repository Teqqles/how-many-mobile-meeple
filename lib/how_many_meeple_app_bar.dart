import 'package:flutter/material.dart';
import 'package:how_many_mobile_meeple/platform/pages.dart';
import 'package:how_many_mobile_meeple/save_dialog.dart';

import 'app_common.dart';
import 'components/empty_widget.dart';
import 'model/model.dart';

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
                  icon: Icon(Icons.home),
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (BuildContext context) =>
                            Pages.platformPages().homePage()));
                  }),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(AppCommon.appTitle),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
              hasSaveDialog
                  ? IconButton(
                      icon: Icon(Icons.save),
                      onPressed: model != null
                          ? () => showDialog(
                              context: context,
                              builder: (context) => SaveDialog(
                                    model: model,
                                  ))
                          : null)
                  : EmptyWidget()
            ],
          ),
        );
}
