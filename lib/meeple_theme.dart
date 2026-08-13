import 'package:flutter/material.dart';

/// Maps the persisted `themeMode` setting value to a Flutter [ThemeMode].
/// Unknown or empty values fall back to [ThemeMode.system] so old permalinks
/// and missing settings degrade gracefully.
ThemeMode themeModeFromString(String value) {
  switch (value) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
}

class MeepleTheme {
  static const MaterialColor meepleGreen = MaterialColor(
    _greenPrimaryValue,
    <int, Color>{
      50: Color(0xFFE8F5E9),
      100: Color(0xFFC8E6C9),
      200: Color(0xFFA5D6A7),
      300: Color(0xFF81C784),
      400: Color(0xFF66BB6A),
      500: Color(_greenPrimaryValue),
      600: Color(0xFF43A047),
      700: Color(0xFF388E3C),
      800: Color(0xFF2E7D32),
      900: Color(0xFF1B5E20),
    },
  );
  static const MaterialColor meepleBlue = MaterialColor(
    _bluePrimaryValue,
    <int, Color>{
      50: Color(0xFFECEFF1),
      100: Color(0xFFCFD8DC),
      200: Color(0xFFB0BEC5),
      300: Color(0xFF90A4AE),
      400: Color(0xFF78909C),
      500: Color(_bluePrimaryValue),
      600: Color(0xFF546E7A),
      700: Color(0xFF455A64),
      800: Color(0xFF37474F),
      900: Color(0xFF263238),
    },
  );

  static const MaterialColor meepleRed = MaterialColor(
    _redPrimaryValue,
    <int, Color>{
      50: Color(0xFFFFEBEE),
      100: Color(0xFFFFCDD2),
      200: Color(0xFFEF9A9A),
      300: Color(0xFFE57373),
      400: Color(0xFFEF5350),
      500: Color(_redPrimaryValue),
      600: Color(0xFFE53935),
      700: Color(0xFFD32F2F),
      800: Color(0xFFC62828),
      900: Color(0xFFB71C1C),
    },
  );
  static const MaterialColor meeplePurple = MaterialColor(
    _purplePrimaryValue,
    <int, Color>{
      50: Color(0xFFF2EEF7),
      100: Color(0xFFDFD4EC),
      200: Color(0xFFC7B4DD),
      300: Color(0xFFAE93CE),
      400: Color(0xFF9678BF),
      500: Color(_purplePrimaryValue),
      600: Color(0xFF6A4C93),
      700: Color(0xFF574A78),
      800: Color(0xFF453961),
      900: Color(0xFF2E2743),
    },
  );
  static const int _redPrimaryValue = 0xffb71a1a;
  static const int _bluePrimaryValue = 0xff2c5285;
  static const int _greenPrimaryValue = 0xff269e31;
  static const int _purplePrimaryValue = 0xff7e5aa8;

  /// A hand-picked dark-mode palette expressed as a five-stop ramp from
  /// lightest ([c0], the accent) to darkest ([c4], the scaffold background).
  /// Designed for dark mode rather than inverted from the light swatch.
  static const DarkPalette mintnight = DarkPalette(
    Color(0xFF7CBBAE),
    Color(0xFF63968B),
    Color(0xFF4A7068),
    Color(0xFF324B46),
    Color(0xFF192523),
  );
  static const DarkPalette darkRed = DarkPalette(
    Color(0xFFEF9A9A),
    Color(0xFFC62828),
    Color(0xFF6E1E1E),
    Color(0xFF3E1214),
    Color(0xFF260C0D),
  );
  static const DarkPalette darkTeal = DarkPalette(
    Color(0xFF3AA895),
    Color(0xFF006D57),
    Color(0xFF085D5A),
    Color(0xFF0C4A50),
    Color(0xFF082F35),
  );
  static const DarkPalette purple = DarkPalette(
    Color(0xFF9E86C4),
    Color(0xFF6F5D94),
    Color(0xFF574A78),
    Color(0xFF3D3357),
    Color(0xFF241D33),
  );

  /// Random-selectable theme pairs. The same index picks a light swatch and its
  /// companion dark palette, so an accent stays coherent across a mode switch
  /// within a session.
  static const List<MaterialColor> lightSwatches = [
    meepleGreen,
    meepleRed,
    meepleBlue,
    meeplePurple,
  ];
  static const List<DarkPalette> darkPalettes = [
    mintnight,
    darkRed,
    darkTeal,
    purple,
  ];

  /// Light theme seeded from [swatch]. Preserves the app's original look:
  /// white text/icons on the coloured primary buttons and switch styling.
  static ThemeData light(MaterialColor swatch) {
    return ThemeData(
      primarySwatch: swatch,
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: swatch,
        brightness: Brightness.light,
      ).copyWith(
        onPrimary: Colors.white, // White text on primary color buttons
      ),
      highlightColor: swatch.shade50,
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : swatch.shade600,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? swatch.shade600
              : Colors.white,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => swatch.shade600,
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
          backgroundColor: swatch,
        ),
      ),
    );
  }

  static const Color _darkOnSurface = Color(0xFFECECEC);

  /// Dark theme built from a curated [DarkPalette], designed for dark mode
  /// rather than inverted from the light swatch. Chrome (app bar, floating
  /// buttons, headers, and primary/secondary buttons) all use a single
  /// palette tone so the UI stays consistent; surfaces are the palette's
  /// darker tones and the lightest tone is the interactive accent.
  static ThemeData dark(DarkPalette p) {
    // Seed a full, harmonious dark scheme from the palette accent so every
    // role (containers, outline, tertiary, ...) is tonally consistent - then
    // lock the roles the app paints directly to the exact palette tones. This
    // stops Material's default baseline colours leaking through container-based
    // widgets (e.g. source chips) as an off-palette "old scheme".
    final scheme = ColorScheme.fromSeed(
      seedColor: p.chrome,
      brightness: Brightness.dark,
    ).copyWith(
      primary: p.chrome,
      onPrimary: Colors.white,
      secondary: p.chrome,
      onSecondary: Colors.white,
      surface: p.surface,
      onSurface: _darkOnSurface,
      surfaceContainerHighest: p.surfaceAlt,
      tertiary: p.accent,
      onTertiary: Colors.black,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      // Single flat body colour, like light mode: scaffold, cards, drawers and
      // dialogs all share the off-black [surface] tone so there is no lighter
      // outer body or lighter inner card. Material 3 would otherwise tint cards
      // lighter with an elevation overlay, so surfaceTint is killed below and
      // depth is carried by the zebra ([highlightColor]) and chip/elevated
      // ([surfaceContainerHighest]) tones instead.
      scaffoldBackgroundColor: p.surface,
      canvasColor: p.surface,
      cardColor: p.surface,
      cardTheme: CardThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
      ),
      highlightColor: p.zebra,
      dividerColor: Colors.white24,
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? p.accent : _darkOnSurface,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? p.chrome : p.surfaceAlt,
        ),
        trackOutlineColor:
            WidgetStateProperty.resolveWith((states) => p.accent),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: p.chrome,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: p.chrome,
        ),
      ),
    );
  }
}

/// A five-stop dark-mode colour ramp, lightest ([c0]) to darkest ([c4]), with
/// semantic role getters so the theme builder reads clearly.
class DarkPalette {
  final Color c0;
  final Color c1;
  final Color c2;
  final Color c3;
  final Color c4;

  const DarkPalette(this.c0, this.c1, this.c2, this.c3, this.c4);

  /// Flat body colour (darkest): scaffold, cards, drawers, dialogs, lists.
  Color get surface => c4;

  /// Gentle alternate-row (zebra) highlight, one step up from [surface].
  Color get zebra => c3;

  /// Chips and elevated containers - a stronger step up so they read clearly.
  Color get surfaceAlt => c2;

  /// App bar, floating buttons, and primary/secondary buttons (white text).
  Color get chrome => c1;

  /// Interactive accent: selected states, switches, links (lightest).
  Color get accent => c0;
}
