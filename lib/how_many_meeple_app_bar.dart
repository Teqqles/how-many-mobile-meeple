import 'package:flutter/material.dart';
import 'package:how_many_mobile_meeple/save_dialog.dart';

import 'model/model.dart';

class HowManyMeepleAppBar extends AppBar {
  HowManyMeepleAppBar(String subtitle,
      {BuildContext context, bool hasSaveDialog = false, AppModel model})
      : super(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('How Many Meeple?'),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
              hasSaveDialog
                  ? IconButton(
                      icon: Icon(Icons.save),
                      onPressed: (model == null || model.items.isEmpty)
                          ? null
                          : () => showDialog(
                              context: context,
                              builder: (context) => SaveDialog(
                                    model: model,
                                  )))
                  : Text("")
            ],
          ),
        );
} // todo redraw on any form changes to allow data to populate button
