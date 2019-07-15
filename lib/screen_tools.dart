import 'package:flutter/cupertino.dart';

abstract class ScreenTools {
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
