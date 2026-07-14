import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the user's chosen app language, persists it to shared_preferences
/// so it survives app restarts, and notifies listeners (MaterialApp's
/// Consumer) whenever it changes. Defaults to English until the user
/// picks something else in Settings.
class LocaleProvider extends ChangeNotifier {
  static const String _prefsKey = 'minime_locale_code';

  /// Order languages appear in the picker, with a human label key for
  /// each (see AppTheme-style label lookup in the Settings screen).
  static const List<String> supportedCodes = [
    'en',
    'ro',
    'es',
    'fr',
    'ru',
    'de',
    'it',
    'pt',
    'pl',
  ];

  Locale _locale = const Locale('en');

  Locale get locale => _locale;
  String get languageCode => _locale.languageCode;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved != null && supportedCodes.contains(saved)) {
      _locale = Locale(saved);
      notifyListeners();
    }
  }

  Future<void> setLocale(String code) async {
    if (!supportedCodes.contains(code) || code == _locale.languageCode) return;
    _locale = Locale(code);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, code);
  }
}
