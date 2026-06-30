// coverage:ignore-file
import 'package:flutter/material.dart';

class HeadingText extends Text {
  HeadingText(String data, BuildContext context)
      : super(data,
            style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.bold));
}
