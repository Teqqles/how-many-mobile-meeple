import 'dart:math';

import 'package:flutter/material.dart';
import 'package:how_many_mobile_meeple/platform/pages.dart';
import 'package:how_many_mobile_meeple/platform/router.dart' as r;

import 'package:provider/provider.dart';

import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';
import 'package:how_many_mobile_meeple/app_config.dart';
import 'package:how_many_mobile_meeple/play_log/play_log_service.dart';
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

  // One random index picks both the light swatch and its companion dark
  // palette, so the accent stays coherent if the user flips light/dark.
  static final int _themeIndex =
      Random().nextInt(MeepleTheme.lightSwatches.length);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(create: (_) {
      final model = AppModel();
      PlayLogService.instance().then(model.attachPlayLog);
      return model;
    }, child: Consumer<AppModel>(
      builder: (context, model, _) {
        final mode = themeModeFromString(
            model.settings.setting(Settings.themeMode.name).getString());
        return MaterialApp(
          title: 'How Many Meeple?',
          theme: MeepleTheme.light(MeepleTheme.lightSwatches[_themeIndex]),
          darkTheme: MeepleTheme.dark(MeepleTheme.darkPalettes[_themeIndex]),
          themeMode: mode,
          home: Pages.platformPages().homePage(),
          onGenerateRoute: r.Router.generateRoute,
        );
      },
    ));
  }
}
