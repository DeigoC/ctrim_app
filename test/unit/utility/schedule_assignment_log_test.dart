import 'package:ctrim_app/models/event/event_program.dart';
import 'package:ctrim_app/utility/schedule_assignment_log.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _role({
  String title = 'Praise and Worship',
  DateTime? start,
  DateTime? end,
}) =>
    {'id': 1, 'title': title, 'start': start, 'end': end, 'uids': <String>[]};

void main() {
  final nine = DateTime(2026, 10, 11, 9, 30);
  final quarterPastTen = DateTime(2026, 10, 11, 10, 15);

  group('describe', () {
    test('null when the same people are kept in another order', () {
      expect(
        ScheduleAssignmentLog.describe(
          role: _role(),
          wholeEvent: true,
          before: ['a', 'b'],
          after: ['b', 'a'],
        ),
        isNull,
      );
    });

    test('whole-event role with people added', () {
      expect(
        ScheduleAssignmentLog.describe(
          role: _role(start: nine),
          wholeEvent: true,
          before: [],
          after: ['a', 'b'],
        ),
        'Updated Praise and Worship whole-event schedule: added 2 people',
      );
    });

    test('timed role with one person removed', () {
      expect(
        ScheduleAssignmentLog.describe(
          role: _role(title: 'Sound', start: nine, end: quarterPastTen),
          wholeEvent: false,
          before: ['a', 'b'],
          after: ['a'],
        ),
        'Updated Sound schedule (09:30–10:15): removed 1 person',
      );
    });
  });

  group('subject', () {
    test('whole event leaves the clock off', () {
      expect(
        ScheduleAssignmentLog.subject(
          role: _role(start: nine, end: quarterPastTen),
          wholeEvent: true,
        ),
        'Praise and Worship whole-event schedule',
      );
    });

    test('running-order slot shows its range', () {
      expect(
        ScheduleAssignmentLog.subject(
          role: _role(title: 'Sound', start: nine, end: quarterPastTen),
          wholeEvent: false,
        ),
        'Sound schedule (09:30–10:15)',
      );
    });

    test('start only reads "from"', () {
      expect(
        ScheduleAssignmentLog.subject(
          role: _role(title: 'Sound', start: nine),
          wholeEvent: false,
        ),
        'Sound schedule (from 09:30)',
      );
    });

    test('no times', () {
      expect(
        ScheduleAssignmentLog.subject(
          role: _role(title: 'Sound'),
          wholeEvent: false,
        ),
        'Sound schedule',
      );
    });

    test('blank title', () {
      expect(
        ScheduleAssignmentLog.subject(
          role: _role(title: '  '),
          wholeEvent: true,
        ),
        'Untitled role whole-event schedule',
      );
    });

    test('long title is cut', () {
      final subject = ScheduleAssignmentLog.subject(
        role: _role(title: 'x' * 100),
        wholeEvent: false,
      );
      expect(subject, '${'x' * 59}… schedule');
    });
  });

  group('change', () {
    test('added', () {
      expect(
        ScheduleAssignmentLog.change(added: 1, removed: 0, remaining: 3),
        'added 1 person',
      );
      expect(
        ScheduleAssignmentLog.change(added: 3, removed: 0, remaining: 3),
        'added 3 people',
      );
    });

    test('removed with people left', () {
      expect(
        ScheduleAssignmentLog.change(added: 0, removed: 2, remaining: 1),
        'removed 2 people',
      );
    });

    test('removed everyone', () {
      expect(
        ScheduleAssignmentLog.change(added: 0, removed: 1, remaining: 0),
        'removed 1 person, now unassigned',
      );
    });

    test('same number in and out is a swap', () {
      expect(
        ScheduleAssignmentLog.change(added: 1, removed: 1, remaining: 2),
        'swapped 1 person',
      );
      expect(
        ScheduleAssignmentLog.change(added: 2, removed: 2, remaining: 2),
        'swapped 2 people',
      );
    });

    test('uneven add and remove', () {
      expect(
        ScheduleAssignmentLog.change(added: 2, removed: 1, remaining: 3),
        'added 2 people, removed 1 person',
      );
    });
  });

  group('isWholeEventRole', () {
    DateTime at(int hour, [int minute = 0]) =>
        DateTime(2026, 10, 11, hour, minute);

    EventProgram service() {
      final program = EventProgram();
      program.addRole(
          uids: [], title: 'Welcome', start: at(9), end: at(9, 30), id: 1);
      program.addRole(
          uids: [], title: 'Sermon', start: at(10), end: at(11), id: 2);
      program.addRole(
          uids: [], title: 'Prayer', start: at(11), end: at(11, 30), id: 3);
      return program;
    }

    test('flagged standing role', () {
      final program = service()
        ..addRole(
          uids: [],
          title: 'Praise and Worship',
          start: null,
          end: null,
          id: 4,
          standing: true,
        );
      expect(
        ScheduleAssignmentLog.isWholeEventRole(program: program, roleId: 4),
        isTrue,
      );
    });

    test('long unflagged line lifted into the band', () {
      final program = service()
        ..addRole(uids: [], title: 'Sound', start: at(9), end: at(12), id: 4);
      expect(
        ScheduleAssignmentLog.isWholeEventRole(program: program, roleId: 4),
        isTrue,
      );
    });

    test('running-order slot', () {
      expect(
        ScheduleAssignmentLog.isWholeEventRole(program: service(), roleId: 2),
        isFalse,
      );
    });
  });
}
