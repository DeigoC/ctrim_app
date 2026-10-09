import 'package:ctrim_app/src/localization/app_localizations.dart';
import 'package:ctrim_app/utility/app_context.dart';
import 'package:ctrim_app/utility/event_context.dart';
import 'package:ctrim_app/widgets/posts/schedule_timeline_block.dart';
import 'package:ctrim_app/widgets/posts/view_all_programs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('wide schedule eases the detail pane and timeline together',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpSchedule(tester);

    double paneWidth() => tester.getSize(find.byType(SizeTransition)).width;
    double timelineWidth() =>
        tester.getSize(find.byType(ScheduleTimelineBlock).first).width;

    final closedTimeline = timelineWidth();
    expect(paneWidth(), lessThan(1));
    expect(find.byIcon(Icons.close), findsNothing);

    await tester.tap(find.byType(ScheduleTimelineBlock).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));

    final midOpenPane = paneWidth();
    final midOpenTimeline = timelineWidth();
    expect(midOpenPane, greaterThan(40));
    expect(midOpenPane, lessThan(300));
    expect(midOpenTimeline, lessThan(closedTimeline - 30));

    await tester.pumpAndSettle();

    final openPane = paneWidth();
    final openTimeline = timelineWidth();
    expect(openPane, closeTo(320, 1));
    expect(closedTimeline - openTimeline, closeTo(320, 2));
    expect(find.byIcon(Icons.close), findsOneWidget);
    expect(find.text('Welcome'), findsWidgets);

    await tester.tap(find.byType(ScheduleTimelineBlock).at(1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(paneWidth(), closeTo(320, 1));
    await tester.pumpAndSettle();
    expect(find.text('Word'), findsWidgets);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));

    final midClosePane = paneWidth();
    final midCloseTimeline = timelineWidth();
    expect(midClosePane, greaterThan(20));
    expect(midClosePane, lessThan(300));
    expect(midCloseTimeline, greaterThan(openTimeline + 30));

    await tester.pumpAndSettle();
    expect(paneWidth(), lessThan(1));
    expect(timelineWidth(), closeTo(closedTimeline, 1));
    expect(find.byIcon(Icons.close), findsNothing);
  });
}

Future<void> _pumpSchedule(WidgetTester tester) async {
  final prefs = await SharedPreferences.getInstance();
  final appContext = AppContext(
    prefInstance: prefs,
    cacheDir: null,
    appDir: null,
  );
  final eventContext = EventContext.adding(currentUserID: '0');
  final start = DateTime(2026, 6, 14, 10);
  eventContext.head.setEventDate(start);
  eventContext.program.setFinishTime(DateTime(2026, 6, 14, 11));
  eventContext.program.addRole(
    uids: const [],
    title: 'Welcome',
    start: start,
    end: DateTime(2026, 6, 14, 10, 15),
    id: 1,
  );
  eventContext.program.addRole(
    uids: const [],
    title: 'Word',
    start: DateTime(2026, 6, 14, 10, 30),
    end: DateTime(2026, 6, 14, 11),
    id: 2,
  );

  await tester.pumpWidget(
    ChangeNotifierProvider<AppContext>.value(
      value: appContext,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ViewAllPrograms(
            eventContext: eventContext,
            onProgramChanged: () {},
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
