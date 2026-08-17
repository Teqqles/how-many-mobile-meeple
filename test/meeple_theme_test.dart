@Tags(['unit'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_many_mobile_meeple/meeple_theme.dart';

void main() {
  group('themeModeFromString', () {
    test('maps "light" to ThemeMode.light', () {
      expect(themeModeFromString('light'), ThemeMode.light);
    });

    test('maps "dark" to ThemeMode.dark', () {
      expect(themeModeFromString('dark'), ThemeMode.dark);
    });

    test('maps "system" to ThemeMode.system', () {
      expect(themeModeFromString('system'), ThemeMode.system);
    });

    test('falls back to ThemeMode.system for unknown values', () {
      expect(themeModeFromString('nonsense'), ThemeMode.system);
      expect(themeModeFromString(''), ThemeMode.system);
    });
  });

  group('MeepleTheme factories', () {
    test('light() builds a light theme from the swatch', () {
      final theme = MeepleTheme.light(MeepleTheme.meepleBlue);
      expect(theme.colorScheme.brightness, Brightness.light);
    });

    test('dark() builds a dark theme from a palette', () {
      final theme = MeepleTheme.dark(MeepleTheme.mintnight);
      expect(theme.colorScheme.brightness, Brightness.dark);
    });

    test('dark() uses the palette chrome as primary and secondary', () {
      final theme = MeepleTheme.dark(MeepleTheme.mintnight);
      expect(theme.colorScheme.primary, MeepleTheme.mintnight.chrome);
      expect(theme.colorScheme.secondary, MeepleTheme.mintnight.chrome);
    });

    test('dark() builds for every palette without error', () {
      for (final palette in MeepleTheme.darkPalettes) {
        expect(
          MeepleTheme.dark(palette).colorScheme.brightness,
          Brightness.dark,
        );
      }
    });

    test('light and dark selection lists stay aligned', () {
      expect(MeepleTheme.lightSwatches.length, MeepleTheme.darkPalettes.length);
    });
  });
}
