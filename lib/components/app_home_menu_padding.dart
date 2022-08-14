import 'package:flutter/cupertino.dart';

class AppHomeMenuPadding extends Padding {
  static const defaultPadding = EdgeInsets.all(2.0);

  const AppHomeMenuPadding({
    Key key,
    EdgeInsetsGeometry padding,
    Widget child,
  }) : super(key: key, padding: padding ?? defaultPadding, child: child);
}
