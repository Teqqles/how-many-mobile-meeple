import 'package:flutter/cupertino.dart';

class AppHomeMenuPadding extends Padding {
  static const defaultPadding = EdgeInsets.all(2.0);

  const AppHomeMenuPadding({
    super.key,
    super.padding = defaultPadding,
    super.child = const SizedBox.shrink(),
  });
}
