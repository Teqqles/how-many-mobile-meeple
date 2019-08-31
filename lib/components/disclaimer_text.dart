import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DisclaimerText extends Text {
  DisclaimerText(String data, BuildContext context)
      : super(data,
            style: TextStyle(color: Theme.of(context).disabledColor));
}
