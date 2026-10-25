import 'package:ctrim_app/models/event/event_attendance.dart';
import 'package:ctrim_app/models/event/event_head.dart';
import 'package:ctrim_app/utility/attendance_newcomer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AttendanceNewcomer', () {
    EventHead post({
      required String id,
      required DateTime? date,
      List<String> groups = const [],
      List<String> tags = const [],
    }) {
      final head = EventHead(id: id, cellGroupIDs: groups, tagIDs: tags);
      head.setEventDate(date);
      return head;
    }

    EventAttendance people(List<String> userIds) {
      final attendance = EventAttendance();
      for (final userId in userIds) {
        attendance.addAttendee(AttendeeEntry.user(
          userId: userId,
          displayName: userId,
          addedBy: 'staff',
        ));
      }
      return attendance;
    }

    AttendanceSeriesPost seriesPost({
      required String id,
      required DateTime date,
      List<String> groups = const [],
      List<String> tags = const [],
      List<String> userIds = const [],
    }) {
      return AttendanceSeriesPost(
        head: post(id: id, date: date, groups: groups, tags: tags),
        attendance: people(userIds),
      );
    }

    final today = DateTime(2026, 10, 25, 19);
    final week1 = DateTime(2026, 10, 4, 19);
    final week2 = DateTime(2026, 10, 11, 19);
    final week3 = DateTime(2026, 10, 18, 19);

    List<AttendanceSeriesPost> threeGroupWeeks({
      List<String> week1People = const [],
      List<String> week2People = const [],
      List<String> week3People = const [],
    }) {
      return [
        seriesPost(
          id: 'w1',
          date: week1,
          groups: const ['cg-a'],
          userIds: week1People,
        ),
        seriesPost(
          id: 'w2',
          date: week2,
          groups: const ['cg-a'],
          userIds: week2People,
        ),
        seriesPost(
          id: 'w3',
          date: week3,
          groups: const ['cg-a'],
          userIds: week3People,
        ),
      ];
    }

    test('a cell group is the series even when the post has a tag', () {
      final head = post(
        id: 'now',
        date: today,
        groups: const ['cg-a'],
        tags: const ['sunday'],
      );

      expect(AttendanceNewcomer.scopeFor(head).usesCellGroups, isTrue);
      expect(AttendanceNewcomer.scopeFor(head).ids, ['cg-a']);
    });

    test('no cell group falls back to the post tags', () {
      final head =
          post(id: 'now', date: today, tags: const ['sunday', 'youth']);

      final scope = AttendanceNewcomer.scopeFor(head);
      expect(scope.usesCellGroups, isFalse);
      expect(scope.ids, ['sunday', 'youth']);
    });

    test('no date, no cell group, and no tag do not mark anyone', () {
      final attendees = people(const ['ada']);

      expect(
        AttendanceNewcomer.marksFor(
          current: post(id: 'now', date: null, groups: const ['cg-a']),
          attendees: attendees.attendees,
          earlier: threeGroupWeeks(week1People: const ['x']),
        ),
        isEmpty,
      );
      expect(
        AttendanceNewcomer.marksFor(
          current: post(id: 'now', date: today),
          attendees: attendees.attendees,
          earlier: threeGroupWeeks(),
        ),
        isEmpty,
      );
    });

    test('marks wait until three earlier lists have been saved', () {
      final current = post(id: 'now', date: today, groups: const ['cg-a']);
      final earlier =
          threeGroupWeeks(week1People: const ['ada']).take(2).toList();

      expect(
        AttendanceNewcomer.marksFor(
          current: current,
          attendees: people(const ['ben']).attendees,
          earlier: earlier,
        ),
        isEmpty,
      );
    });

    test('first, second, and third visits are marked, then the row is plain',
        () {
      final current = post(id: 'now', date: today, groups: const ['cg-a']);
      final marks = AttendanceNewcomer.marksFor(
        current: current,
        attendees:
            people(const ['new', 'second', 'third', 'regular']).attendees,
        earlier: threeGroupWeeks(
          week1People: const ['second', 'third', 'regular'],
          week2People: const ['third', 'regular'],
          week3People: const ['regular'],
        ),
      );

      expect(marks['new'], AttendanceVisitMark.first);
      expect(marks['second'], AttendanceVisitMark.returning);
      expect(marks['third'], AttendanceVisitMark.returning);
      expect(marks.containsKey('regular'), isFalse);
    });

    test('another cell group and a later post do not count', () {
      final current = post(id: 'now', date: today, groups: const ['cg-a']);
      final marks = AttendanceNewcomer.marksFor(
        current: current,
        attendees: people(const ['ada']).attendees,
        earlier: [
          ...threeGroupWeeks(
            week1People: const ['host'],
            week2People: const ['host'],
            week3People: const ['host'],
          ),
          seriesPost(
            id: 'other',
            date: week1,
            groups: const ['cg-b'],
            userIds: const ['ada'],
          ),
          seriesPost(
            id: 'later',
            date: DateTime(2026, 11, 1),
            groups: const ['cg-a'],
            userIds: const ['ada'],
          ),
          seriesPost(
            id: 'now',
            date: week3,
            groups: const ['cg-a'],
            userIds: const ['ada'],
          ),
        ],
      );

      expect(marks['ada'], AttendanceVisitMark.first);
    });

    test('two linked groups share one history', () {
      final current = post(
        id: 'now',
        date: today,
        groups: const ['cg-a', 'cg-b'],
      );
      final marks = AttendanceNewcomer.marksFor(
        current: current,
        attendees: people(const ['ada']).attendees,
        earlier: [
          seriesPost(
            id: 'a1',
            date: week1,
            groups: const ['cg-a'],
            userIds: const ['ada'],
          ),
          seriesPost(
            id: 'b1',
            date: week2,
            groups: const ['cg-b'],
            userIds: const ['ada'],
          ),
          seriesPost(
            id: 'a2',
            date: week3,
            groups: const ['cg-a'],
            userIds: const ['someone'],
          ),
        ],
      );

      expect(marks['ada'], AttendanceVisitMark.returning);
    });

    test('a tag series uses the tag they already know best', () {
      final current = post(
        id: 'now',
        date: today,
        tags: const ['sunday', 'youth'],
      );
      final marks = AttendanceNewcomer.marksFor(
        current: current,
        attendees: people(const ['regular', 'youth']).attendees,
        earlier: [
          seriesPost(
            id: 's1',
            date: week1,
            tags: const ['sunday'],
            userIds: const ['regular'],
          ),
          seriesPost(
            id: 's2',
            date: week2,
            tags: const ['sunday'],
            userIds: const ['regular'],
          ),
          seriesPost(
            id: 's3',
            date: week3,
            tags: const ['sunday', 'youth'],
            userIds: const ['regular', 'youth'],
          ),
        ],
      );

      expect(marks.containsKey('regular'), isFalse);
      expect(marks['youth'], AttendanceVisitMark.returning);
    });

    test('a cell group does not inherit a tag the meeting also carries', () {
      final current = post(
        id: 'now',
        date: today,
        groups: const ['cg-a'],
        tags: const ['sunday'],
      );
      final marks = AttendanceNewcomer.marksFor(
        current: current,
        attendees: people(const ['ada']).attendees,
        earlier: [
          ...threeGroupWeeks(
            week1People: const ['host'],
            week2People: const ['host'],
            week3People: const ['host'],
          ),
          seriesPost(
            id: 'sunday',
            date: week1,
            tags: const ['sunday'],
            userIds: const ['ada'],
          ),
        ],
      );

      expect(marks['ada'], AttendanceVisitMark.first);
    });

    test('a free-text name is never marked', () {
      final attendance = people(const []);
      attendance.addAttendee(AttendeeEntry.external(
        name: 'Guest Friend',
        addedBy: 'staff',
      ));
      final current = post(id: 'now', date: today, groups: const ['cg-a']);

      expect(
        AttendanceNewcomer.marksFor(
          current: current,
          attendees: attendance.attendees,
          earlier: threeGroupWeeks(week1People: const ['x']),
        ),
        isEmpty,
      );
    });
  });
}
