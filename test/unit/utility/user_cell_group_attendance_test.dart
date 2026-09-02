import 'package:flutter_test/flutter_test.dart';

import 'package:ctrim_app/models/event/event_attendance.dart';
import 'package:ctrim_app/models/event/event_head.dart';
import 'package:ctrim_app/utility/user_cell_group_attendance.dart';

void main() {
  group('UserCellGroupAttendance', () {
    EventHead meeting({
      required String id,
      required DateTime eventDate,
      required List<String> cellGroupIDs,
    }) {
      final head = EventHead(id: id, title: 'Meeting');
      head.setEventDate(eventDate);
      head.setCellGroupIDs(cellGroupIDs);
      return head;
    }

    test('meetingsForMemberGroups filters and sorts by event date', () {
      final rows = UserCellGroupAttendance.meetingsForMemberGroups(
        pastMeetings: [
          meeting(
            id: 'm2',
            eventDate: DateTime(2024, 7, 10),
            cellGroupIDs: ['cg-a'],
          ),
          meeting(
            id: 'm1',
            eventDate: DateTime(2024, 7, 5),
            cellGroupIDs: ['cg-a'],
          ),
          meeting(
            id: 'other',
            eventDate: DateTime(2024, 7, 6),
            cellGroupIDs: ['cg-other'],
          ),
        ],
        memberGroupIds: {'cg-a'},
      );

      expect(rows.map((h) => h.id).toList(), ['m1', 'm2']);
    });

    test('summarize reports attended when user is on attendee list', () {
      final meetings = [
        meeting(
          id: 'm1',
          eventDate: DateTime(2024, 7, 5),
          cellGroupIDs: ['cg-a'],
        ),
        meeting(
          id: 'm2',
          eventDate: DateTime(2024, 7, 12),
          cellGroupIDs: ['cg-a'],
        ),
      ];

      final summary = UserCellGroupAttendance.summarize(
        userId: 'u1',
        memberMeetings: meetings,
        attendanceByPostId: {
          'm1': EventAttendance()
            ..addAttendee(
              AttendeeEntry.user(
                userId: 'u1',
                displayName: 'One',
                addedBy: 'leader',
              ),
            ),
          'm2': EventAttendance(),
        },
      );

      expect(summary.attendedInPastWindow, isTrue);
      expect(summary.meetingsInWindow, 2);
      expect(summary.meetingsAttended, 1);
      expect(summary.distinctGroupsAttended, 1);
      expect(summary.lastAttendedDate, DateTime(2024, 7, 5));
      expect(summary.lastAttendedMeeting?.id, 'm1');
    });

    test('summarize counts distinct groups when meetings span groups', () {
      final meetings = [
        meeting(
          id: 'm1',
          eventDate: DateTime(2024, 7, 5),
          cellGroupIDs: ['cg-a'],
        ),
        meeting(
          id: 'm2',
          eventDate: DateTime(2024, 7, 12),
          cellGroupIDs: ['cg-b'],
        ),
      ];

      final summary = UserCellGroupAttendance.summarize(
        userId: 'u1',
        memberMeetings: meetings,
        attendanceByPostId: {
          'm1': EventAttendance()
            ..addAttendee(
              AttendeeEntry.user(
                userId: 'u1',
                displayName: 'One',
                addedBy: 'leader',
              ),
            ),
          'm2': EventAttendance()
            ..addAttendee(
              AttendeeEntry.user(
                userId: 'u1',
                displayName: 'One',
                addedBy: 'leader',
              ),
            ),
        },
        memberGroupIds: {'cg-a', 'cg-b'},
      );

      expect(summary.meetingsAttended, 2);
      expect(summary.distinctGroupsAttended, 2);
      expect(summary.lastAttendedMeeting?.id, 'm2');
    });

    test('summarize reports no attendance when user never checked in', () {
      final meetings = [
        meeting(
          id: 'm1',
          eventDate: DateTime(2024, 7, 5),
          cellGroupIDs: ['cg-a'],
        ),
      ];

      final summary = UserCellGroupAttendance.summarize(
        userId: 'u1',
        memberMeetings: meetings,
        attendanceByPostId: {
          'm1': EventAttendance()
            ..addAttendee(
              AttendeeEntry.user(
                userId: 'u2',
                displayName: 'Other',
                addedBy: 'leader',
              ),
            ),
        },
      );

      expect(summary.attendedInPastWindow, isFalse);
      expect(summary.meetingsAttended, 0);
      expect(summary.lastAttendedDate, isNull);
    });

    test('summarize returns empty when there are no meetings', () {
      final summary = UserCellGroupAttendance.summarize(
        userId: 'u1',
        memberMeetings: const [],
        attendanceByPostId: const {},
      );

      expect(summary.attendedInPastWindow, isFalse);
      expect(summary.meetingsInWindow, 0);
    });
  });
}
