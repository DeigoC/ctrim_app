import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:go_router/go_router.dart';

import '../utility/responsive_layout.dart';
import 'app_router.dart';
import 'localization/app_localizations.dart';
import 'settings/settings_controller.dart';

class MyApp extends StatefulWidget {
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
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router = createAppRouter();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.settingsController,
      builder: (BuildContext context, Widget? child) {
        return MaterialApp.router(
          title: 'CTRIM App',
          restorationScopeId: 'app',
          routerConfig: _router,
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
          theme: MyApp._themeFor(),
          darkTheme: MyApp._themeFor(brightness: Brightness.dark),
          themeMode: widget.settingsController.themeMode,
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
        );
      },
    );
  }
}
