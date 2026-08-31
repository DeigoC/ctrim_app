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
}
