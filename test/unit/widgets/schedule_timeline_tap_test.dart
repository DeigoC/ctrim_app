import 'package:ctrim_app/models/user.dart';
import 'package:ctrim_app/utility/schedule_timeline_layout.dart';
import 'package:ctrim_app/widgets/posts/schedule_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> role({
  required int id,
  required String title,
  required DateTime start,
  required DateTime end,
}) {
  return <String, dynamic>{
    'uids': <String>[],
    'detail': '',
    'title': title,
    'start': start,
    'end': end,
    'for_guests': true,
    'id': id,
  };
}

void main() {
  final layout = ScheduleTimelineLayout.build(roles: [
    role(
      id: 1,
      title: 'Welcome',
      start: DateTime(2026, 6, 14, 10, 0),
      end: DateTime(2026, 6, 14, 10, 15),
    ),
    role(
      id: 2,
      title: 'Word',
      start: DateTime(2026, 6, 14, 11, 0),
      end: DateTime(2026, 6, 14, 11, 30),
    ),
  ]);

  Future<void> pumpTimeline(
    WidgetTester tester, {
    required void Function(DateTime start) onEmptyTap,
    required void Function(Map<String, dynamic> role) onRoleTap,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 400,
              child: ScheduleTimeline(
                layout: layout,
                usersForRole: (_) => const <User>[],
                onRoleTap: onRoleTap,
                onEmptyTap: onEmptyTap,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('a tap in a gap reports the snapped start time', (tester) async {
    DateTime? tapped;
    var roleTaps = 0;
    await pumpTimeline(
      tester,
      onEmptyTap: (start) => tapped = start,
      onRoleTap: (_) => roleTaps++,
    );

    final origin = tester.getTopLeft(find.byType(ScheduleTimeline));
    await tester.tapAt(origin + const Offset(80, 150));
    await tester.pump();

    expect(tapped, DateTime(2026, 6, 14, 10, 30));
    expect(roleTaps, 0);
  });

  testWidgets('a tap on a block opens that item', (tester) async {
    DateTime? tapped;
    String? opened;
    await pumpTimeline(
      tester,
      onEmptyTap: (start) => tapped = start,
      onRoleTap: (role) => opened = role['title'] as String,
    );

    await tester.tap(find.text('Welcome'));
    await tester.pump();

    expect(opened, 'Welcome');
    expect(tapped, isNull);
  });
}
