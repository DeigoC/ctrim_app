import 'package:ctrim_app/models/event/event_head.dart';
import 'package:ctrim_app/models/event/event_program.dart';
import 'package:ctrim_app/models/user.dart';
import 'package:ctrim_app/src/localization/app_localizations.dart';
import 'package:ctrim_app/utility/app_context.dart';
import 'package:ctrim_app/utility/team_rota.dart';
import 'package:ctrim_app/widgets/personal/team_rota_schedule_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('on-duty faces are not repeated on the running order',
      (tester) async {
    await _pump(tester, const Size(400, 1400));

    expect(find.text('On duty'), findsOneWidget);
    expect(find.text('Running order'), findsOneWidget);
    expect(find.text("You're on Praise and Worship, Opening, and Closing"),
        findsOneWidget);
    expect(find.text('Same as Praise and Worship'), findsNWidgets(2));
    expect(find.text('Diego'), findsOneWidget);
    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('Unassigned'), findsOneWidget);
    expect(find.text('4 people'), findsOneWidget);
    expect(find.text('No one assigned'), findsOneWidget);
  });

  testWidgets('a wide window lays the same morning out without overflow',
      (tester) async {
    await _pump(tester, const Size(1200, 900));

    expect(find.text('On duty'), findsOneWidget);
    expect(find.text('Same as Praise and Worship'), findsNWidgets(2));
    expect(find.text('Diego'), findsOneWidget);
  });
}

Future<void> _pump(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final prefs = await SharedPreferences.getInstance();
  final me = User(id: 'me', forname: 'Diego', surname: 'Cruz');
  final ada = User(id: 'ada', forname: 'Ada', surname: 'Allen');
  final ben = User(id: 'ben', forname: 'Ben', surname: 'Bell');
  final cam = User(id: 'cam', forname: 'Cam', surname: 'Cole');
  final dee = User(id: 'dee', forname: 'Dee', surname: 'Dunn');
  final day = DateTime(2026, 10, 18);
  DateTime at(int hour, [int minute = 0]) =>
      DateTime(day.year, day.month, day.day, hour, minute);

  final head = EventHead(
    id: 'sunday',
    title: 'Sunday Worship Service',
    location: 'Belfast',
  )..setEventDate(at(9));
  final program = EventProgram()
    ..addRole(
      id: 1,
      title: 'Praise and Worship',
      start: at(9),
      end: null,
      uids: const ['me', 'ada', 'ben'],
      tagIDs: const ['worship'],
      standing: true,
    )
    ..addRole(
      id: 2,
      title: 'Opening',
      start: at(10, 10),
      end: at(10, 35),
      uids: const ['me', 'ada', 'ben'],
      tagIDs: const ['worship'],
    )
    ..addRole(
      id: 3,
      title: 'Prayer',
      start: at(10, 35),
      end: at(10, 40),
      uids: const [],
      tagIDs: const ['speakers'],
    )
    ..addRole(
      id: 4,
      title: 'Closing',
      start: at(11, 40),
      end: at(11, 45),
      uids: const ['me', 'ada', 'ben'],
      tagIDs: const ['worship'],
    )
    ..addRole(
      id: 5,
      title: 'Benediction',
      start: at(11, 45),
      end: at(11, 50),
      uids: const [],
    )
    ..addRole(
      id: 6,
      title: 'Clean up',
      start: at(15),
      end: at(15, 30),
      uids: const ['ada', 'ben', 'cam', 'dee'],
      tagIDs: const ['cleaners'],
    );

  final appContext = AppContext(
    prefInstance: prefs,
    cacheDir: null,
    appDir: null,
    user: me,
    allUsers: [me, ada, ben, cam, dee],
  );

  await tester.pumpWidget(
    ChangeNotifierProvider<AppContext>.value(
      value: appContext,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: TeamRotaScheduleView(
            head: head,
            roles: TeamRotaQuery.rolesInStartOrder(program),
            selectedTagIDs: const {},
            onRoleTap: (_) {},
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
