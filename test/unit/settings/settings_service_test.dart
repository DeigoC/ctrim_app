import 'package:ctrim_app/src/settings/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsService theme mode', () {
    test('defaults to system when unset', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = SettingsService(prefs);

      expect(await service.themeMode(), ThemeMode.system);
    });

    test('persists and reloads light, dark, and system', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = SettingsService(prefs);

      await service.updateThemeMode(ThemeMode.light);
      expect(await service.themeMode(), ThemeMode.light);

      await service.updateThemeMode(ThemeMode.dark);
      expect(await service.themeMode(), ThemeMode.dark);

      await service.updateThemeMode(ThemeMode.system);
      expect(await service.themeMode(), ThemeMode.system);
    });

    test('encode/decode round-trips', () {
      for (final mode in ThemeMode.values) {
        expect(
          SettingsService.decodeThemeMode(SettingsService.encodeThemeMode(mode)),
          mode,
        );
      }
    });

    test('unknown stored value falls back to system', () {
      expect(SettingsService.decodeThemeMode('nope'), ThemeMode.system);
      expect(SettingsService.decodeThemeMode(null), ThemeMode.system);
    });
  });
}
