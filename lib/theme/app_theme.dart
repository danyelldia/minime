import 'package:flutter/material.dart';

/// MiniMe's four selectable color themes: Dark (the original look) plus
/// three light/colored variants - White, Pink, and Navy Blue - so everyone
/// can pick whichever feels most like "home". Picked in Settings, persisted
/// via ThemeProvider.
class AppTheme {
  static const String dark = 'dark';
  static const String white = 'white';
  static const String pink = 'pink';
  static const String blue = 'blue';

  /// Order themes appear in the picker, with a human label for each.
  static const Map<String, String> labels = {
    dark: 'Dark',
    white: 'White',
    pink: 'Pink',
    blue: 'Blue',
  };

  /// Small swatch color shown next to each theme's name in the picker.
  static const Map<String, Color> swatch = {
    dark: Color(0xFF1B1F3B),
    white: Color(0xFF6C7A89),
    pink: Color(0xFFEC4899),
    blue: Color(0xFF1B3A66),
  };

  static ThemeData themeFor(String name) {
    switch (name) {
      case white:
        return _white;
      case pink:
        return _pink;
      case blue:
        return _blue;
      case dark:
      default:
        return _dark;
    }
  }

  static final ThemeData _dark = ThemeData(
    useMaterial3: true,
    colorSchemeSeed: const Color(0xFF4361EE),
    brightness: Brightness.dark,
  );

  static final ThemeData _white = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6C7A89),
      brightness: Brightness.light,
    ).copyWith(surface: Colors.white),
    scaffoldBackgroundColor: Colors.white,
  );

  // Soft, actually-pink background (not just a pink accent on a pale
  // Material default), phone-friendly with dark text for readability.
  static final ThemeData _pink = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFEC4899),
      brightness: Brightness.light,
    ).copyWith(
      surface: const Color(0xFFFCE4EC),
      primary: const Color(0xFFD6448C),
    ),
    scaffoldBackgroundColor: const Color(0xFFFCE4EC),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF8BBD0),
      foregroundColor: Colors.black87,
    ),
    cardColor: const Color(0xFFFFF0F5),
  );

  // Navy, not a bright/pure blue - dark like the Dark theme but with a
  // blue tint throughout, easier on the eyes at night.
  static final ThemeData _blue = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF3A6EA5),
      brightness: Brightness.dark,
    ).copyWith(
      surface: const Color(0xFF0F1B2E),
      primary: const Color(0xFF5C8DFF),
    ),
    scaffoldBackgroundColor: const Color(0xFF0A1526),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0F1B2E),
      foregroundColor: Colors.white,
    ),
    cardColor: const Color(0xFF13233D),
  );
}
