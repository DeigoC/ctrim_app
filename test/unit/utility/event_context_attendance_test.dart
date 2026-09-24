import 'package:ctrim_app/models/event/event_attendance.dart';
import 'package:ctrim_app/models/event/event_head.dart';
import 'package:ctrim_app/models/event/event_metadata.dart';
import 'package:ctrim_app/utility/event_context.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EventContext attendance dirty merge', () {
    EventContext viewingContext() {
      final context = EventContext.viewing(
        eventHead: EventHead(id: 'post-1'),
        currentUID: 'author-1',
      );
      context.setFetchedMetadata(EventMetadata(authorUID: 'author-1'));
      return context;
    }

    EventAttendance serverSnapshot({
      required List<AttendeeEntry> attendees,
      List<String> expectedUserIds = const [],
      Map<String, InterestedEntry>? interested,
    }) {
      return EventAttendance.fromMap({
        'interested': {
          for (final e in (interested ?? {}).entries) e.key: e.value.toJson(),
        },
        'attendees': attendees.map((e) => e.toJson()).toList(),
        'expectedUserIds': expectedUserIds,
      });
    }

    test('forceReplace false keeps dirty attendees across refetch', () {
      final context = viewingContext();
      context.setFetchedAttendance(
        serverSnapshot(
          attendees: [
            AttendeeEntry.user(
              userId: 'u-1',
              displayName: 'One',
              addedBy: 'author-1',
            ),
          ],
          expectedUserIds: const ['u-1'],
        ),
        forceReplace: true,
      );

      context.applyStaffAttendanceEdit(
        serverSnapshot(
          attendees: [
            AttendeeEntry.user(
              userId: 'u-1',
              displayName: 'One',
              addedBy: 'author-1',
            ),
            AttendeeEntry.user(
              userId: 'u-2',
              displayName: 'Two',
              addedBy: 'author-1',
            ),
          ],
          expectedUserIds: const ['u-1', 'u-2'],
        ),
      );
      expect(context.isAttendanceDirty, isTrue);
      expect(context.attendance!.attendeeCount, 2);

      // Simulates People tab remount that used to call forceReplace: true.
      context.setFetchedAttendance(
        serverSnapshot(
          attendees: [
            AttendeeEntry.user(
              userId: 'u-1',
              displayName: 'One',
              addedBy: 'author-1',
            ),
          ],
          expectedUserIds: const ['u-1'],
          interested: {
            'auth-x': InterestedEntry(
              authId: 'auth-x',
              displayName: 'New interest',
              userId: 'u-9',
            ),
          },
        ),
        forceReplace: false,
      );

      expect(context.isAttendanceDirty, isTrue);
      expect(context.attendance!.attendeeCount, 2);
      expect(context.attendance!.expectedUserIds, ['u-1', 'u-2']);
      expect(context.attendance!.interestedCount, 1);
      expect(context.canSaveTheEditing, isTrue);
    });

    test('collectRoleRemovalUserIds includes removed expected attendees', () {
      final context = viewingContext();
      context.setFetchedAttendance(
        serverSnapshot(
          attendees: const [],
          expectedUserIds: const ['u-1', 'u-2'],
        ),
        forceReplace: true,
      );

      context.applyStaffAttendanceEdit(
        serverSnapshot(
          attendees: const [],
          expectedUserIds: const ['u-2'],
        ),
      );

      expect(context.collectRoleRemovalUserIds(), ['u-1']);
    });

    test('forceReplace true wipes dirty staff lists', () {
      final context = viewingContext();
      context.setFetchedAttendance(
        serverSnapshot(attendees: const []),
        forceReplace: true,
      );
      context.applyStaffAttendanceEdit(
        serverSnapshot(
          attendees: [
            AttendeeEntry.user(
              userId: 'u-2',
              displayName: 'Two',
              addedBy: 'author-1',
            ),
          ],
        ),
      );

      context.setFetchedAttendance(
        serverSnapshot(attendees: const []),
        forceReplace: true,
      );

      expect(context.isAttendanceDirty, isFalse);
      expect(context.attendance!.attendeeCount, 0);
    });
  });

  group('EventContext draft attendees on create', () {
    AttendeeEntry person(String id) => AttendeeEntry.user(
          userId: id,
          displayName: id,
          addedBy: 'author-1',
        );

    test('past-dated drafts keep selected attendees with expected people', () {
      final context = EventContext.adding(currentUserID: 'author-1');
      context.head.setEventDate(DateTime(2020, 3, 1, 19));
      context.applyExpectedAttendeeUserIDs(['u-1', 'u-2']);
      context.applyDraftAttendees([
        person('u-2'),
        person('u-2'),
        person('u-3'),
        AttendeeEntry.external(name: 'Guest', addedBy: 'author-1'),
      ]);

      expect(context.draftAttendees.map((e) => e.userId), ['u-2', 'u-3']);

      final attendance = context.buildAttendanceForNewPost(
        expectedUserIds: context.expectedAttendeeUserIDs,
        now: DateTime(2026, 9, 24),
      );
      expect(attendance.expectedUserIds, ['u-1', 'u-2']);
      expect(attendance.attendees.map((e) => e.userId), ['u-2', 'u-3']);
    });

    test('upcoming and undated drafts do not publish attendees', () {
      final upcoming = EventContext.adding(currentUserID: 'author-1');
      upcoming.head.setEventDate(DateTime(2026, 10, 1, 19));
      upcoming.applyDraftAttendees([person('u-1')]);

      final upcomingAttendance = upcoming.buildAttendanceForNewPost(
        expectedUserIds: const ['u-9'],
        now: DateTime(2026, 9, 24),
      );
      expect(upcomingAttendance.attendeeCount, 0);
      expect(upcomingAttendance.expectedUserIds, ['u-9']);

      final undated = EventContext.adding(currentUserID: 'author-1');
      undated.applyDraftAttendees([person('u-1')]);
      expect(
        undated.buildAttendanceForNewPost(
          expectedUserIds: const [],
          now: DateTime(2026, 9, 24),
        ).attendeeCount,
        0,
      );
    });
  });
}
