import 'package:flutter/material.dart';
import '../theme_extensions.dart';

class DrawerHeading extends Container {
  DrawerHeading(String filterTitle, BuildContext context)
      : super(
          margin: EdgeInsets.only(top: 8),
          padding: EdgeInsets.all(12),
          color: Theme.of(context).colorScheme.secondary,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Text(
                filterTitle,
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: 15,
                    color: Theme.of(context).selectedRowColor,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
}
