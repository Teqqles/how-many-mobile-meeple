import 'package:flutter/material.dart';

class HowManyMeepleAppBar extends AppBar {
  HowManyMeepleAppBar(String subtitle)
      : super(
          title: Column(
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
        );
}
