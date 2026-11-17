import 'package:ctrim_app/src/localization/app_localizations.dart';
import 'package:ctrim_app/widgets/posts/post_edit_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('schedule and related posts open inside the sheet',
      (tester) async {
    var added = 0;
    var createdChild = 0;
    await _pump(
      tester,
      _sheet(
        isLeader: true,
        hasParent: true,
        onAddSchedule: () => added++,
        onCreateChild: () => createdChild++,
      ),
    );

    expect(find.text('Edit About'), findsOneWidget);
    expect(find.text('Add Schedule'), findsNothing);
    expect(find.text('Create Child Post'), findsNothing);
    expect(find.text('Broadcast'), findsOneWidget);

    await tester.tap(find.text('Schedule'));
    await tester.pumpAndSettle();

    expect(find.text('Add Schedule'), findsOneWidget);
    expect(find.text('Arrange schedule'), findsOneWidget);
    expect(find.text('Apply schedule preset'), findsOneWidget);
    expect(find.text('Edit About'), findsNothing);

    await tester.tap(find.text('Add Schedule'));
    expect(added, 1);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Edit About'), findsOneWidget);
    expect(find.text('Add Schedule'), findsNothing);

    await tester.tap(find.text('Create related posts'));
    await tester.pumpAndSettle();

    expect(find.text('Create Sibling Post'), findsOneWidget);
    expect(find.text('Create Child Post'), findsOneWidget);
    expect(find.text('Bulk Create Related Posts'), findsOneWidget);
    expect(find.text('Edit About'), findsNothing);
    expect(
      find.text('A sibling, a child, or several at once'),
      findsOneWidget,
    );

    await tester.tap(find.text('Create Child Post'));
    expect(createdChild, 1);
  });

  testWidgets('a post without a parent omits the sibling action',
      (tester) async {
    await _pump(tester, _sheet(isLeader: true, hasParent: false));

    await tester.tap(find.text('Create related posts'));
    await tester.pumpAndSettle();

    expect(find.text('Create Sibling Post'), findsNothing);
    expect(find.text('Create Child Post'), findsOneWidget);
    expect(find.text('A child post, or several at once'), findsOneWidget);
  });

  testWidgets('contributors do not see leader actions', (tester) async {
    await _pump(tester, _sheet(isLeader: false, hasParent: true));

    expect(find.text('Schedule'), findsOneWidget);
    expect(find.text('Apply expected attendance'), findsOneWidget);
    expect(find.text('Create related posts'), findsNothing);
    expect(find.text('Broadcast'), findsNothing);
    expect(find.text('Scheduled members'), findsNothing);
  });

  testWidgets('system back leaves schedule before the sheet closes',
      (tester) async {
    await _openInSheet(tester);

    await tester.tap(find.text('Schedule'));
    await tester.pumpAndSettle();
    expect(find.text('Add Schedule'), findsOneWidget);

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    expect(await navigator.maybePop(), isTrue);
    await tester.pumpAndSettle();

    expect(find.text('Add Schedule'), findsNothing);
    expect(find.text('Edit About'), findsOneWidget);

    expect(await navigator.maybePop(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('Edit About'), findsNothing);
  });
}

PostEditSheet _sheet({
  required bool isLeader,
  required bool hasParent,
  VoidCallback? onAddSchedule,
  VoidCallback? onCreateChild,
}) {
  return PostEditSheet(
    isLeader: isLeader,
    hasParent: hasParent,
    onEditAbout: () {},
    onEditTitle: () {},
    onAddSchedule: onAddSchedule ?? () {},
    onArrangeSchedule: () {},
    onApplySchedulePreset: () {},
    onApplyExpectedAttendancePreset: () {},
    onEditMedia: () {},
    onManageContributors: () {},
    onManageLeadSpeaker: () {},
    onOpenPeopleTab: () {},
    onCreateSibling: () {},
    onCreateChild: onCreateChild ?? () {},
    onBulkCreate: () {},
    onNotifyBroadcast: () {},
    onNotifyScheduled: () {},
  );
}

Future<void> _pump(WidgetTester tester, Widget sheet) async {
  _useTallSurface(tester);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: sheet),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openInSheet(WidgetTester tester) async {
  _useTallSurface(tester);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                builder: (_) => _sheet(isLeader: true, hasParent: false),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void _useTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
