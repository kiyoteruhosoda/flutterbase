import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the app-wide [ThemeMode] and persists the user's choice.
class ThemeViewModel extends ChangeNotifier {
  ThemeViewModel(this._prefs) {
    _themeMode = _loadFromPrefs();
  }

  static const String _prefKey = 'theme_mode';

  final SharedPreferences _prefs;
  late ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    await _prefs.setString(_prefKey, _encode(mode));
    notifyListeners();
  }

  ThemeMode _loadFromPrefs() {
    final saved = _prefs.getString(_prefKey);
    return switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.light, // Default: light mode
    };
  }

  String _encode(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };
}
