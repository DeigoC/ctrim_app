import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../pages/home_page.dart';
import '../utility/responsive_layout.dart';
import 'localization/app_localizations.dart';
import 'settings/settings_controller.dart';

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.settingsController,
  });

  final SettingsController settingsController;

  static ThemeData _themeFor({Brightness? brightness}) {
    final base = brightness == null
        ? ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue)
        : ThemeData(
            brightness: brightness,
            useMaterial3: true,
            colorSchemeSeed: Colors.blue);
    // Override Flutter's default 640px sheet cap; width is refined per-frame in [builder].
    return base.copyWith(
      bottomSheetTheme: base.bottomSheetTheme.copyWith(
        constraints: const BoxConstraints(
            maxWidth: ResponsiveLayout.desktopContentMaxWidth),
      ),
      dialogTheme: DialogThemeData(
        constraints: const BoxConstraints(
            maxWidth: ResponsiveLayout.reviewDialogMaxWidth),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        clipBehavior: Clip.antiAlias,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settingsController,
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(
          title: 'CTRIM App',
          restorationScopeId: 'app',
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            FlutterQuillLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''),
          ],
          // onGenerateTitle: (BuildContext context) => AppLocalizations.of(context)!.appTitle,
          theme: _themeFor(),
          darkTheme: _themeFor(brightness: Brightness.dark),
          themeMode: settingsController.themeMode,
          builder: (context, child) {
            final theme = Theme.of(context);
            return Theme(
              data: theme.copyWith(
                bottomSheetTheme: theme.bottomSheetTheme.copyWith(
                  constraints:
                      ResponsiveLayout.bottomSheetConstraintsOf(context),
                ),
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const HomePage(),
        );
      },
    );
  }
}
