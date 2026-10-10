import 'package:ctrim_app/src/localization/app_localizations.dart';
import 'package:ctrim_app/widgets/common/permalink_app_bar_leading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('a root post link offers Home and opens the bulletin',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/post/abc',
      routes: [
        GoRoute(
          path: '/bulletin',
          builder: (_, __) => const Scaffold(body: Text('Bulletin')),
        ),
        GoRoute(
          path: '/post/:id',
          builder: (context, _) => Scaffold(
            appBar: AppBar(
              leading: PermalinkAppBarLeading.homeOrNull(context),
              title: const Text('Post'),
            ),
          ),
        ),
      ],
    );

    await tester.pumpWidget(_app(router));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);

    await tester.tap(find.byTooltip('Home'));
    await tester.pumpAndSettle();

    expect(find.text('Bulletin'), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/bulletin');
  });

  testWidgets('opening a post from the bulletin keeps Back', (tester) async {
    final router = GoRouter(
      initialLocation: '/bulletin',
      routes: [
        GoRoute(
          path: '/bulletin',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () => context.push('/post/abc'),
              child: const Text('Open post'),
            ),
          ),
        ),
        GoRoute(
          path: '/post/:id',
          builder: (context, _) => Scaffold(
            appBar: AppBar(
              leading: PermalinkAppBarLeading.homeOrNull(context),
              title: const Text('Post'),
            ),
          ),
        ),
      ],
    );

    await tester.pumpWidget(_app(router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open post'));
    await tester.pumpAndSettle();

    expect(find.byType(BackButton), findsOneWidget);
    expect(find.byIcon(Icons.home_outlined), findsNothing);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Open post'), findsOneWidget);
  });

  testWidgets('a church subpage pops to the church, which offers Home',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/churches/belfast/pastors',
      routes: [
        GoRoute(
          path: '/ctrim',
          builder: (_, __) => const Scaffold(body: Text('CTRIM')),
        ),
        GoRoute(
          path: '/churches/:id',
          builder: (context, _) => Scaffold(
            appBar: AppBar(
              leading: PermalinkAppBarLeading.homeOrNull(context),
              title: const Text('Church'),
            ),
          ),
          routes: [
            GoRoute(
              path: 'pastors',
              builder: (context, _) => Scaffold(
                appBar: AppBar(
                  leading: PermalinkAppBarLeading.homeOrNull(context),
                  title: const Text('Pastors'),
                ),
              ),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(_app(router));
    await tester.pumpAndSettle();

    expect(find.text('Pastors'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
    expect(find.byIcon(Icons.home_outlined), findsNothing);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Church'), findsOneWidget);
    expect(find.byIcon(Icons.home_outlined), findsOneWidget);

    await tester.tap(find.byTooltip('Home'));
    await tester.pumpAndSettle();
    expect(find.text('CTRIM'), findsOneWidget);
  });
}

Widget _app(GoRouter router) {
  return MaterialApp.router(
    routerConfig: router,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  );
}
