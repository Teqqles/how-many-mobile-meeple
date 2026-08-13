import 'package:flutter/material.dart';
import 'package:how_many_mobile_meeple/meeple_theme.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';

/// Compact System / Light / Dark selector for the settings drawer. Writes the
/// chosen mode to the persisted `themeMode` setting and stores immediately so
/// the theme flips live. Kept intentionally small (11pt, compact density) so
/// three labelled segments fit the narrow drawer without horizontal scroll.
class ThemeModeControl extends StatelessWidget {
  final AppModel model;

  const ThemeModeControl(this.model, {super.key});

  static String _toValue(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = themeModeFromString(
        model.settings.setting(Settings.themeMode.name).getString());
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 6),
            child: Text('Theme', style: TextStyle(fontSize: 13)),
          ),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                textStyle: const TextStyle(fontSize: 11),
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('System'),
                  icon: Icon(Icons.brightness_auto, size: 16),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode, size: 16),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode, size: 16),
                ),
              ],
              selected: {current},
              onSelectionChanged: (selection) {
                model.settings.setting(Settings.themeMode.name).value =
                    _toValue(selection.first);
                model.updateStore();
              },
            ),
          ),
        ],
      ),
    );
  }
}
