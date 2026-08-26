import 'package:flutter_test/flutter_test.dart';

import 'package:ctrim_app/models/cell_group.dart';
import 'package:ctrim_app/models/event/event_head.dart';
import 'package:ctrim_app/utility/cell_group_activity_stats.dart';

void main() {
  group('CellGroupActivityStats', () {
    final now = DateTime(2026, 8, 21, 15, 30);

    EventHead meeting({
      required String id,
      required DateTime eventDate,
      List<String> cellGroupIDs = const ['cg1'],
      int attendees = 0,
    }) {
      final head = EventHead(
        id: id,
        title: 'CG meeting',
        cellGroupIDs: cellGroupIDs,
      );
      head.setEventDate(eventDate);
      head.setAttendeeCount(attendees);
      return head;
    }

    test('empty when no groups or meetings', () {
      final stats = CellGroupActivityStats.compute(
        groups: const [],
        meetings: const [],
        now: now,
      );

      expect(stats.pastMeetingsCount, 0);
      expect(stats.pastAttendeesTotal, 0);
      expect(stats.upcomingMeetingsCount, 0);
      expect(stats.distinctGroupsMetPast, 0);
      expect(stats.activeGroupsCount, 0);
      expect(stats.averagePastAttendance, isNull);
    });

    test('counts past meetings and attendees in 3-week window', () {
      final stats = CellGroupActivityStats.compute(
        groups: [
          CellGroup(id: 'cg1', name: 'A', memberCount: 10),
          CellGroup(id: 'cg2', name: 'B', memberCount: 5),
        ],
        meetings: [
          meeting(
            id: '1',
            eventDate: DateTime(2026, 8, 1, 19),
            attendees: 8,
          ),
          meeting(
            id: '2',
            eventDate: DateTime(2026, 8, 14, 19),
            cellGroupIDs: ['cg2'],
            attendees: 6,
          ),
          // Exactly 21 days before today midnight — included
          meeting(
            id: '3',
            eventDate: DateTime(2026, 7, 31, 10),
            attendees: 4,
          ),
          // Before past window — excluded
          meeting(
            id: '4',
            eventDate: DateTime(2026, 7, 30, 23),
            attendees: 99,
          ),
        ],
        now: now,
      );

      expect(stats.pastMeetingsCount, 3);
      expect(stats.pastAttendeesTotal, 18);
      expect(stats.distinctGroupsMetPast, 2);
      expect(stats.averagePastAttendance, 6);
      expect(stats.activeGroupsCount, 2);
      expect(stats.totalActiveMembers, 15);
    });

    test('counts upcoming meetings from today through next 6 days', () {
      final stats = CellGroupActivityStats.compute(
        groups: [CellGroup(id: 'cg1', name: 'A')],
        meetings: [
          // Today (incl.)
          meeting(id: 'today', eventDate: DateTime(2026, 8, 21, 9)),
          // Last day of window (today + 6)
          meeting(id: 'day6', eventDate: DateTime(2026, 8, 27, 19)),
          // Day after window — excluded
          meeting(id: 'day7', eventDate: DateTime(2026, 8, 28, 0)),
          // Yesterday — past, not upcoming
          meeting(id: 'yest', eventDate: DateTime(2026, 8, 20, 19), attendees: 3),
        ],
        now: now,
      );

      expect(stats.upcomingMeetingsCount, 2);
      expect(stats.pastMeetingsCount, 1);
      expect(stats.pastAttendeesTotal, 3);
    });

    test('ignores heads without event date or cell group link', () {
      final noDate = EventHead(id: 'nd', title: 'x', cellGroupIDs: ['cg1']);
      final noCg = meeting(
        id: 'nc',
        eventDate: DateTime(2026, 8, 20),
        cellGroupIDs: const [],
        attendees: 5,
      );

      final stats = CellGroupActivityStats.compute(
        groups: [CellGroup(id: 'cg1', name: 'A', memberCount: 2)],
        meetings: [noDate, noCg],
        now: now,
      );

      expect(stats.pastMeetingsCount, 0);
      expect(stats.pastAttendeesTotal, 0);
      expect(stats.upcomingMeetingsCount, 0);
    });

    test('excludes archived groups from catalogue counts', () {
      final stats = CellGroupActivityStats.compute(
        groups: [
          CellGroup(id: '1', name: 'Active', memberCount: 4),
          CellGroup(
            id: '2',
            name: 'Paused',
            status: CellGroupStatus.paused,
            memberCount: 3,
          ),
          CellGroup(
            id: '3',
            name: 'Archived',
            status: CellGroupStatus.archived,
            memberCount: 20,
          ),
        ],
        meetings: const [],
        now: now,
      );

      expect(stats.activeGroupsCount, 1);
      expect(stats.pausedGroupsCount, 1);
      expect(stats.totalActiveMembers, 4);
    });

    test('query range covers past and upcoming windows', () {
      expect(
        CellGroupActivityStats.pastWindowStart(now),
        DateTime(2026, 7, 31),
      );
      expect(
        CellGroupActivityStats.upcomingWindowEndExclusive(now),
        DateTime(2026, 8, 28),
      );
      expect(
        CellGroupActivityStats.queryRangeStart(now),
        DateTime(2026, 7, 31),
      );
      expect(
        CellGroupActivityStats.queryRangeEndExclusive(now),
        DateTime(2026, 8, 28),
      );
    });
  });
}
