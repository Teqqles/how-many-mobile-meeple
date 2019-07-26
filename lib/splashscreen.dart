import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:how_many_mobile_meeple/screen_tools.dart';

import 'homepage.dart';

class SplashScreen extends StatefulWidget {
  static final String route = "Splash-page";

  @override
  State<StatefulWidget> createState() {
    return SplashScreenState();
  }
}

class SplashScreenState extends State<SplashScreen> with ScreenTools {
  @override
  void initState() {
    super.initState();

    loadData();
  }

  Future<Timer> loadData() async {
    return new Timer(Duration(seconds: 3), onDoneLoading);
  }

  onDoneLoading() async {
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (context) => HomePage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
          width: getScreenWidthPercentageInPixels(context, 1),
          child: Image.asset(
            'lib/images/howmanymeeple.png',
            fit: BoxFit.cover,
          )),
    );
  }
}
