import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


class DrawerHeading extends Container {
  DrawerHeading(String filterTitle, BuildContext context)
      : super(
          margin: EdgeInsets.only(top: 8),
          padding: EdgeInsets.all(12),
          color: Theme.of(context).accentColor,
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
