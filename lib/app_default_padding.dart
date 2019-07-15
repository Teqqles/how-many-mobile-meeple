import 'package:flutter/cupertino.dart';

class AppDefaultPadding extends Padding {
  static const defaultPadding = EdgeInsets.all(8.0);

  const AppDefaultPadding({
    Key key,
    EdgeInsetsGeometry padding,
    Widget child,
  }) : super(key: key, padding: padding ?? defaultPadding, child: child);
}
