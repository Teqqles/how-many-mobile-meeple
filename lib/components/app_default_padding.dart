import 'package:flutter/cupertino.dart';

class AppDefaultPadding extends Padding {
  static const defaultPadding = EdgeInsets.all(8.0);

  const AppDefaultPadding({
    super.key,
    super.padding = defaultPadding,
    required super.child,
  });
}
