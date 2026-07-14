import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

/// Holds the user's chosen color theme (Dark/White/Pink/Blue), persists it
/// to shared_preferences so it survives app restarts, and notifies
/// listeners (MaterialApp's Consumer) whenever it changes.
class ThemeProvider extends ChangeNotifier {
  static const String _prefsKey = 'minime_theme_name';

  String _themeName = AppTheme.dark;

  String get themeName => _themeName;
  ThemeData get themeData => AppTheme.themeFor(_themeName);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved != null && AppTheme.labels.containsKey(saved)) {
      _themeName = saved;
      notifyListeners();
    }
  }

  Future<void> setTheme(String name) async {
    if (!AppTheme.labels.containsKey(name) || name == _themeName) return;
    _themeName = name;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, name);
  }
}
