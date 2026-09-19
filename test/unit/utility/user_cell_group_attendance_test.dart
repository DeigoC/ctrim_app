import 'package:flutter_test/flutter_test.dart';

import 'package:ctrim_app/models/cell_group.dart';
import 'package:ctrim_app/models/event/event_attendance.dart';
import 'package:ctrim_app/models/event/event_head.dart';
import 'package:ctrim_app/models/user.dart';
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
      expect(summary.meetingsHosted, 0);
      expect(summary.meetingsParticipated, 1);
      expect(summary.distinctGroupsAttended, 1);
      expect(summary.lastAttendedDate, DateTime(2024, 7, 5));
      expect(summary.lastAttendedMeeting?.id, 'm1');
      expect(
          summary.recentMeetings.map((r) => r.head.id).toList(), ['m2', 'm1']);
      expect(summary.recentMeetings.map((r) => r.attended).toList(),
          [false, true]);
      expect(
          summary.recentMeetings.map((r) => r.hosted).toList(), [false, false]);
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
      expect(summary.meetingsHosted, 0);
      expect(summary.meetingsParticipated, 2);
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
      expect(summary.meetingsHosted, 0);
      expect(summary.meetingsParticipated, 0);
      expect(summary.lastAttendedDate, isNull);
      expect(summary.recentMeetings, hasLength(1));
      expect(summary.recentMeetings.single.attended, isFalse);
      expect(summary.recentMeetings.single.hosted, isFalse);
    });

    test('summarize counts a listed leader as present without guest check-in',
        () {
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
                userId: 'u2',
                displayName: 'Guest',
                addedBy: 'leader',
              ),
            ),
          'm2': EventAttendance(),
        },
        memberGroupIds: {'cg-a'},
        ledGroupIds: {'cg-a'},
      );

      expect(summary.attendedInPastWindow, isTrue);
      expect(summary.meetingsAttended, 0);
      expect(summary.meetingsHosted, 2);
      expect(summary.meetingsParticipated, 2);
      expect(summary.distinctGroupsAttended, 1);
      expect(summary.lastAttendedMeeting?.id, 'm2');
      expect(
          summary.recentMeetings.map((r) => r.hosted).toList(), [true, true]);
      expect(summary.recentMeetings.map((r) => r.attended).toList(),
          [false, false]);
      expect(summary.recentMeetings.every((r) => r.participated), isTrue);
    });

    test('summarize does not treat leading a different group as hosting', () {
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
        attendanceByPostId: {'m1': EventAttendance()},
        memberGroupIds: {'cg-a', 'cg-b'},
        ledGroupIds: {'cg-b'},
      );

      expect(summary.attendedInPastWindow, isFalse);
      expect(summary.meetingsHosted, 0);
      expect(summary.recentMeetings.single.hosted, isFalse);
    });

    test('summarize does not double-count a host who is also an attendee', () {
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
                userId: 'u1',
                displayName: 'Host',
                addedBy: 'leader',
              ),
            ),
        },
        memberGroupIds: {'cg-a'},
        ledGroupIds: {'cg-a'},
      );

      expect(summary.meetingsAttended, 1);
      expect(summary.meetingsHosted, 1);
      expect(summary.meetingsParticipated, 1);
      expect(summary.recentMeetings.single.attended, isTrue);
      expect(summary.recentMeetings.single.hosted, isTrue);
    });

    test('summarize mixes hosting one group with attending another', () {
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
          'm1': EventAttendance(),
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
        ledGroupIds: {'cg-a'},
      );

      expect(summary.attendedInPastWindow, isTrue);
      expect(summary.meetingsAttended, 1);
      expect(summary.meetingsHosted, 1);
      expect(summary.meetingsParticipated, 2);
      expect(summary.distinctGroupsAttended, 2);
    });

    test('summarize returns empty when there are no meetings', () {
      final summary = UserCellGroupAttendance.summarize(
        userId: 'u1',
        memberMeetings: const [],
        attendanceByPostId: const {},
      );

      expect(summary.attendedInPastWindow, isFalse);
      expect(summary.meetingsInWindow, 0);
      expect(summary.meetingsHosted, 0);
      expect(summary.meetingsParticipated, 0);
      expect(summary.recentMeetings, isEmpty);
    });

    test('ledGroupIdsFor includes catalogue leaders by user and auth id', () {
      final user = User(id: 'u1', forname: 'Ann', surname: 'Lee', authID: 'a1');
      final groups = [
        CellGroup(id: 'cg-a', name: 'Alpha', leaderUserIds: ['u1']),
        CellGroup(id: 'cg-b', name: 'Beta', leaderAuthIds: ['a1']),
        CellGroup(id: 'cg-c', name: 'Gamma', leaderUserIds: ['u-other']),
      ];

      expect(
        UserCellGroupAttendance.ledGroupIdsFor(user: user, groups: groups),
        {'cg-a', 'cg-b'},
      );
    });
  });
}
