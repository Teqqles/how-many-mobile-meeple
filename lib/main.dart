import 'dart:math';

import 'package:flutter/material.dart';
import 'package:how_many_mobile_meeple/platform/pages.dart';
import 'package:how_many_mobile_meeple/platform/router.dart' as r;

import 'package:provider/provider.dart';

import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/app_config.dart';

import 'meeple_theme.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Load configuration (API URL from config file for web)
  await AppConfig.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final List<MaterialColor> _swatchList = [
    MeepleTheme.meepleBlue,
    MeepleTheme.meepleGreen,
    MeepleTheme.meepleRed
  ];

  static final MaterialColor _swatch = _swatchList[Random().nextInt(_swatchList.length)];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (_) => AppModel(),
        child: MaterialApp(
          title: 'How Many Meeple?',
          theme: ThemeData(
            primarySwatch: _swatch,
            colorScheme: ColorScheme.fromSwatch(
              primarySwatch: _swatch,
              brightness: Brightness.light,
            ),
            highlightColor: _swatch.shade50,
          ),
          home: Pages.platformPages().homePage(),
          onGenerateRoute: r.Router.generateRoute,
        ));
  }
}
