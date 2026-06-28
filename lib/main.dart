import 'dart:math';

import 'package:flutter/material.dart';
import 'package:how_many_mobile_meeple/platform/pages.dart';
import 'package:how_many_mobile_meeple/platform/router.dart' as r;

import 'package:provider/provider.dart';

import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/app_config.dart';
import 'package:how_many_mobile_meeple/pwa/pwa_update_service.dart';

import 'meeple_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppConfig.initialize();

  PwaUpdateService.start();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final List<MaterialColor> _swatchList = [
    MeepleTheme.meepleBlue,
    MeepleTheme.meepleGreen,
    MeepleTheme.meepleRed
  ];

  static final MaterialColor _swatch =
      _swatchList[Random().nextInt(_swatchList.length)];

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
            ).copyWith(
              onPrimary: Colors.white, // White text on primary color buttons
            ),
            highlightColor: _swatch.shade50,
            switchTheme: SwitchThemeData(
              thumbColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? Colors.white
                    : _swatch.shade600,
              ),
              trackColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? _swatch.shade600
                    : Colors.white,
              ),
              trackOutlineColor: WidgetStateProperty.resolveWith(
                (states) => _swatch.shade600,
              ),
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                foregroundColor: Colors.white, // White text/icons
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: _swatch,
              ),
            ),
          ),
          home: Pages.platformPages().homePage(),
          onGenerateRoute: r.Router.generateRoute,
        ));
  }
}
