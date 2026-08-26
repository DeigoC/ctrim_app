import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores and retrieves user settings via [SharedPreferences].
class SettingsService {
  SettingsService(this._prefs);

  final SharedPreferences _prefs;

  static const String _themeModeKey = 'themeMode';

  /// Loads the user's preferred [ThemeMode]. Defaults to [ThemeMode.system].
  Future<ThemeMode> themeMode() async {
    return decodeThemeMode(_prefs.getString(_themeModeKey));
  }

  /// Persists the user's preferred [ThemeMode].
  Future<void> updateThemeMode(ThemeMode theme) async {
    await _prefs.setString(_themeModeKey, encodeThemeMode(theme));
  }

  @visibleForTesting
  static String encodeThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  @visibleForTesting
  static ThemeMode decodeThemeMode(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
}
