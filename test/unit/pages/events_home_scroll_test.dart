import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ctrim_app/models/event/event_head.dart';
import 'package:ctrim_app/pages/events/events_home.dart';
import 'package:ctrim_app/src/localization/app_localizations.dart';
import 'package:ctrim_app/utility/app_context.dart';
import 'package:ctrim_app/widgets/posts/post_head.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late ScrollController scrollController;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'hasSeenBulletinDialog': true,
    });
    prefs = await SharedPreferences.getInstance();
    scrollController = ScrollController();
  });

  tearDown(() {
    scrollController.dispose();
  });

  List<EventHead> _tallFeed() {
    final now = DateTime(2026, 10, 4, 12);
    return [
      for (var i = 0; i < 12; i++)
        EventHead(
          id: 'post-$i',
          title: 'Bulletin post $i',
          subtitle: 'Subtitle for scroll coverage on phone-sized bulletin.',
          location: 'Belfast',
        )
          ..setEventDate(now.add(Duration(days: i)))
          ..setRecentDate(now.subtract(Duration(hours: i))),
    ];
  }

  Future<void> pumpBulletin(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final appContext = AppContext(
      prefInstance: prefs,
      cacheDir: null,
      appDir: null,
      heads: _tallFeed(),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<AppContext>.value(
        value: appContext,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.blue,
          ),
          home: Scaffold(
            body: ViewEventsHome(
              scrollController: scrollController,
              rebuildFunction: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('bulletin scroll view stays always-scrollable without snap expand',
      (tester) async {
    await pumpBulletin(tester);

    expect(find.text('Bulletin'), findsOneWidget);
    expect(find.byType(PostHead), findsWidgets);

    final scrollView =
        tester.widget<CustomScrollView>(find.byType(CustomScrollView));
    expect(scrollView.physics, isA<AlwaysScrollableScrollPhysics>());

    final appBar = tester.widget<SliverAppBar>(find.byType(SliverAppBar));
    expect(appBar.floating, isTrue);
    expect(appBar.snap, isFalse);
    expect(appBar.expandedHeight, isNull);

    // Press feedback should come from InkWell (scroll-friendly), not a
    // competing onTapDown GestureDetector around the whole card.
    expect(
      find.descendant(
        of: find.byType(PostHead).first,
        matching: find.byType(InkWell),
      ),
      findsWidgets,
    );
  });

  testWidgets('bulletin list can scroll down and back up without clamping mid-way',
      (tester) async {
    await pumpBulletin(tester);

    expect(scrollController.hasClients, isTrue);
    expect(scrollController.offset, 0);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();
    final afterDown = scrollController.offset;
    expect(afterDown, greaterThan(100));

    await tester.drag(find.byType(CustomScrollView), const Offset(0, 500));
    await tester.pumpAndSettle();
    expect(scrollController.offset, lessThan(afterDown));
    expect(scrollController.offset, greaterThanOrEqualTo(0));
  });
}
