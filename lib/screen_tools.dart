import 'package:flutter/cupertino.dart';

mixin ScreenTools {
  static const double fiftyPercentScreen = 0.5;
  static const double eightyPercentScreen = 0.8;

  Row pageFrameOutline(BuildContext context, Widget frameContent) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [Flexible(child: frameContent)],
    );
  }

  double getScreenWidthPercentageInPixels(
      BuildContext context, double percentage) {
    double screenWidth = MediaQuery.of(context).size.width;
    return screenWidth * percentage;
  }

  double getScreenHeightPercentageInPixels(
      BuildContext context, double percentage) {
    double screenWidth = MediaQuery.of(context).size.height;
    return screenWidth * percentage;
  }
}
