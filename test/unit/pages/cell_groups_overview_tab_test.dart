import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ctrim_app/models/cell_group.dart';
import 'package:ctrim_app/models/cell_group_roster.dart';
import 'package:ctrim_app/models/user.dart';
import 'package:ctrim_app/pages/cell_groups/cell_groups_overview_tab.dart';
import 'package:ctrim_app/src/localization/app_localizations.dart';
import 'package:ctrim_app/utility/app_context.dart';
import 'package:ctrim_app/utility/cell_group_roster_cache.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    CellGroupRosterCache.resetForTesting();
  });

  tearDown(CellGroupRosterCache.resetForTesting);

  Future<void> pumpOverview(
    WidgetTester tester, {
    required AppContext appContext,
    required VoidCallback onBrowseGroups,
  }) async {
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
            body: CellGroupsOverviewTab(
              onBrowseGroups: onBrowseGroups,
              loadActivityMeetings: () async => const [],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();
    // Overview photo retries a failed download on 1s, 2s, then 3s timers.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 3));
  }

  testWidgets('guest overview teaches and offers browse, without activity',
      (tester) async {
    final appContext = AppContext(
      prefInstance: prefs,
      cacheDir: null,
      appDir: null,
    );
    var browsed = false;

    await pumpOverview(
      tester,
      appContext: appContext,
      onBrowseGroups: () => browsed = true,
    );

    expect(find.text('Life in small groups'), findsOneWidget);
    expect(find.text('What a meeting is like'), findsOneWidget);
    expect(find.text('Bible study'), findsOneWidget);
    expect(find.text('Care and prayer'), findsOneWidget);
    expect(find.text('Fellowship'), findsOneWidget);
    expect(find.text('Find a group'), findsOneWidget);
    expect(
        find.text('Search by name or a postcode such as BT9.'), findsOneWidget);
    expect(find.text('Your group'), findsNothing);
    expect(find.text('Recent meetings'), findsNothing);
    expect(find.text('Meetings over time'), findsNothing);

    await tester.ensureVisible(find.text('Browse groups'));
    await tester.pump();
    await tester.tap(find.text('Browse groups'));
    await tester.pump();
    expect(browsed, isTrue);
  });

  testWidgets('signed-in member sees their group above browse', (tester) async {
    final leader = User(
      id: 'lead',
      forname: 'Pat',
      surname: 'Leader',
      authID: 'auth-lead',
    );
    final me = User(
      id: 'me',
      forname: 'Sam',
      surname: 'Member',
      authID: 'auth-me',
    );
    final group = CellGroup(
      id: 'cg-1',
      name: 'Riverside',
      leaderUserIds: const ['lead'],
    );
    CellGroupRosterCache.put(
      'cg-1',
      CellGroupRoster(
        members: [
          CellGroupRosterMember(userId: 'me'),
        ],
      ),
    );
    final appContext = AppContext(
      prefInstance: prefs,
      cacheDir: null,
      appDir: null,
      user: me,
      allUsers: [me, leader],
      allCellGroups: [group],
    );

    await pumpOverview(
      tester,
      appContext: appContext,
      onBrowseGroups: () {},
    );

    expect(find.text('Your group'), findsOneWidget);
    expect(find.text('Riverside'), findsOneWidget);
    expect(find.text('Led by Pat Leader'), findsOneWidget);
    expect(find.text('Browse groups'), findsOneWidget);
    expect(find.text('Activity'), findsNothing);
    expect(find.text('Recent meetings'), findsNothing);
  });

  testWidgets('people who serve see the activity card', (tester) async {
    final me = User(
      id: 'me',
      forname: 'Pat',
      surname: 'Leader',
      authID: 'auth-me',
      isLeader: true,
    );
    final appContext = AppContext(
      prefInstance: prefs,
      cacheDir: null,
      appDir: null,
      user: me,
      allUsers: [me],
    );

    await pumpOverview(
      tester,
      appContext: appContext,
      onBrowseGroups: () {},
    );

    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('Recent meetings'), findsOneWidget);
    expect(find.text('Meetings over time'), findsOneWidget);
  });
}
