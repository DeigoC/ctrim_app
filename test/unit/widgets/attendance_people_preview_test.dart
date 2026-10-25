import 'package:ctrim_app/models/user.dart';
import 'package:ctrim_app/widgets/posts/attendance_people_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpPreview(
    WidgetTester tester, {
    required int count,
    required bool isWide,
    required bool expanded,
    required VoidCallback onToggle,
  }) async {
    final names = [for (var i = 0; i < count; i++) 'Person $i'];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AttendancePeoplePreview(
            names: names,
            tiles: [for (final name in names) Text(name)],
            overviewUsers: const <User>[],
            isWide: isWide,
            expanded: expanded,
            onToggle: onToggle,
          ),
        ),
      ),
    );
  }

  testWidgets('nine people on a phone fold to a few names and +more',
      (tester) async {
    await pumpPreview(
      tester,
      count: 9,
      isWide: false,
      expanded: false,
      onToggle: () {},
    );

    expect(find.text('Person 0, Person 1, Person 2'), findsOneWidget);
    expect(find.text('+6 more'), findsOneWidget);
    expect(find.text('Person 8'), findsNothing);
  });

  testWidgets('a wide screen still lists nine people', (tester) async {
    await pumpPreview(
      tester,
      count: 9,
      isWide: true,
      expanded: false,
      onToggle: () {},
    );

    expect(find.text('Person 8'), findsOneWidget);
    expect(find.textContaining('more'), findsNothing);
  });

  testWidgets('show less reveals every person', (tester) async {
    await pumpPreview(
      tester,
      count: 9,
      isWide: false,
      expanded: true,
      onToggle: () {},
    );

    expect(find.text('Show less'), findsOneWidget);
    expect(find.text('Person 8'), findsOneWidget);
  });

  testWidgets('a folded line keeps a newcomer chip beside the name',
      (tester) async {
    final names = [for (var i = 0; i < 9; i++) 'Person $i'];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AttendancePeoplePreview(
            names: names,
            nameBadges: [
              const Text('New'),
              for (var i = 1; i < names.length; i++) null,
            ],
            tiles: [for (final name in names) Text('tile $name')],
            overviewUsers: const <User>[],
            isWide: false,
            expanded: false,
            onToggle: () {},
          ),
        ),
      ),
    );

    expect(find.text('Person 0'), findsOneWidget);
    expect(find.text('New'), findsOneWidget);
    expect(find.text('Person 0, Person 1, Person 2'), findsNothing);
    expect(find.text('+6 more'), findsOneWidget);
  });
}
