import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ctrim_app/models/cell_group.dart';
import 'package:ctrim_app/models/user.dart';
import 'package:ctrim_app/pages/cell_groups/edit_cell_group_page.dart';
import 'package:ctrim_app/src/localization/app_localizations.dart';
import 'package:ctrim_app/utility/app_context.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<void> pumpEditor(
    WidgetTester tester, {
    required Size size,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final me = User(
      id: 'me',
      forname: 'Ada',
      surname: 'Admin',
      isAreaAdmin: true,
    );
    final pat = User(id: 'pat', forname: 'Pat', surname: 'Lee');
    final jo = User(id: 'jo', forname: 'Jo', surname: 'Ng');
    final group = CellGroup(
      id: 'cg-1',
      name: 'Riverside',
      summary: 'Young adults',
      leaderUserIds: const ['pat', 'jo'],
    );
    final appContext = AppContext(
      prefInstance: prefs,
      cacheDir: null,
      appDir: null,
      user: me,
      allUsers: [me, pat, jo],
      allCellGroups: [group],
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<AppContext>.value(
        value: appContext,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
          home: EditCellGroupPage(existing: group),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('wide editor puts section cards in two columns', (tester) async {
    await pumpEditor(tester, size: const Size(1400, 1600));

    expect(find.text('About'), findsOneWidget);
    expect(find.text('When and where'), findsOneWidget);
    expect(find.text('Meeting posts'), findsOneWidget);
    expect(find.text('Pat Lee'), findsOneWidget);
    expect(find.text('Jo Ng'), findsOneWidget);

    final name = tester.getTopLeft(find.text('Name'));
    final summary = tester.getTopLeft(find.text('Summary'));
    expect(summary.dx, greaterThan(name.dx + 80));
    expect((summary.dy - name.dy).abs(), lessThan(48));

    final when = tester.getTopLeft(find.text('When and where'));
    final meeting = tester.getTopLeft(find.text('Meeting posts'));
    expect(meeting.dx, greaterThan(when.dx + 200));
    expect((meeting.dy - when.dy).abs(), lessThan(24));

    final weekday = tester.getTopLeft(find.text('Meeting weekday'));
    final time = tester.getTopLeft(find.text('Meeting time'));
    expect(time.dx, greaterThan(weekday.dx + 40));
    expect((time.dy - weekday.dy).abs(), lessThan(48));

    final pat = tester.getTopLeft(find.text('Pat Lee'));
    final jo = tester.getTopLeft(find.text('Jo Ng'));
    expect(jo.dx, greaterThan(pat.dx + 40));
    expect((jo.dy - pat.dy).abs(), lessThan(48));
  });

  testWidgets('narrow editor stacks the section cards', (tester) async {
    await pumpEditor(tester, size: const Size(400, 2800));

    final name = tester.getTopLeft(find.text('Name'));
    final summary = tester.getTopLeft(find.text('Summary'));
    expect(summary.dy, greaterThan(name.dy + 24));
    expect((summary.dx - name.dx).abs(), lessThan(48));

    final when = tester.getTopLeft(find.text('When and where'));
    final meeting = tester.getTopLeft(find.text('Meeting posts'));
    expect(meeting.dy, greaterThan(when.dy + 40));
    expect((meeting.dx - when.dx).abs(), lessThan(16));

    final weekday = tester.getTopLeft(find.text('Meeting weekday'));
    final time = tester.getTopLeft(find.text('Meeting time'));
    expect(time.dy, greaterThan(weekday.dy + 24));
  });
}
