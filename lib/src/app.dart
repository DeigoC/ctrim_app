import 'package:ctrim_app/pages/events/add_event_page.dart';
import 'package:ctrim_app/pages/events/add_program_page.dart';
import 'package:ctrim_app/pages/events/edit_gallery_page.dart';
import 'package:ctrim_app/pages/events/edit_header_page.dart';
import 'package:ctrim_app/pages/events/edit_program_page.dart';
import 'package:ctrim_app/pages/events/view_event_page.dart';
import 'package:ctrim_app/pages/home_page.dart';
import 'package:ctrim_app/pages/view_gallery_page.dart';
import 'package:ctrim_app/utility/event_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../pages/events/edit_body_page.dart';
import 'settings/settings_controller.dart';
// import 'settings/settings_view.dart';

final GoRouter _router = GoRouter(routes: <RouteBase>[
  GoRoute(
    path: '/',
    builder: (BuildContext context, GoRouterState state) {
      return const HomePage();
    },
    routes: <RouteBase>[
      GoRoute(
        path: 'view_gallery',
        name: 'view_gallery',
        builder: (context, state) {
          return const ViewGalleryPage();
        },
      ),
      GoRoute(path: 'add_event', name: 'add_event', builder: (context, state) => const AddEventPage()),
      GoRoute(
          path: 'view_event',
          name: 'view_event',
          builder: (context, state) {
            return const ViewEventPage();
          },
          routes: [
            GoRoute(
              path: 'add_program',
              name: 'add_program',
              builder: (context, state) {
                return AddEventProgramPage(
                  eventContext: state.extra as EventContext,
                );
              },
            ),
            GoRoute(
              path: 'edit_program',
              name: 'edit_program',
              builder: (context, state) {
                return EditEventProgramPage(
                  eventContext: state.extra as EventContext,
                );
              },
            ),
            GoRoute(
              path: 'edit_body',
              name: 'edit_body',
              builder: (context, state) {
                return EditBodyPage(
                  eventContext: state.extra as EventContext,
                );
              },
            ),
            GoRoute(
              path: 'edit_gallery',
              name: 'edit_gallery',
              builder: (context, state) {
                return EditGallerlyPage(
                  eventContext: state.extra as EventContext,
                );
              },
            ),
            GoRoute(
              path: 'edit_header_page',
              name: 'edit_header_page',
              builder: (context, state) {
                return EditEventDetailsPage(
                  eventContext: state.extra as EventContext,
                );
              },
            ),
          ]),
    ],
  )
]);

/// The Widget that configures your application.
class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.settingsController,
  });

  final SettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    // Glue the SettingsController to the MaterialApp.
    //
    // The AnimatedBuilder Widget listens to the SettingsController for changes.
    // Whenever the user updates their settings, the MaterialApp is rebuilt.
    return AnimatedBuilder(
      animation: settingsController,
      builder: (BuildContext context, Widget? child) {
        return MaterialApp.router(
          title: 'CTRIM',
          // Providing a restorationScopeId allows the Navigator built by the
          // MaterialApp to restore the navigation stack when a user leaves and
          // returns to the app after it has been killed while running in the
          // background.
          restorationScopeId: 'app',

          // Provide the generated AppLocalizations to the MaterialApp. This
          // allows descendant Widgets to display the correct translations
          // depending on the user's locale.
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''), // English, no country code
          ],

          // Use AppLocalizations to configure the correct application title
          // depending on the user's locale.
          //
          // The appTitle is defined in .arb files found in the localization
          // directory.
          onGenerateTitle: (BuildContext context) => AppLocalizations.of(context)!.appTitle,

          // Define a light and dark color theme. Then, read the user's
          // preferred ThemeMode (light, dark, or system default) from the
          // SettingsController to display the correct theme.
          theme: ThemeData(),
          darkTheme: ThemeData.dark(),
          themeMode: settingsController.themeMode,

          // Define a function to handle named routes in order to support
          // Flutter web url navigation and deep linking.
          // onGenerateRoute: (RouteSettings routeSettings) {
          //   return MaterialPageRoute<void>(
          //     settings: routeSettings,
          //     builder: (BuildContext context) {
          //       switch (routeSettings.name) {
          //         case SettingsView.routeName:
          //           return SettingsView(controller: settingsController);

          //         case EditBodyPage.routeName:
          //           return const EditBodyPage();

          //         case HomePage.routeName:
          //         default:
          //           return const HomePage();
          //       }
          //     },
          //   );
          // },
          routerConfig: _router,
        );
      },
    );
  }
}
