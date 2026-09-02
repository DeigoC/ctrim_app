import 'package:ctrim_app/models/event/event_head.dart';
import 'package:ctrim_app/utility/cell_group_detail_activity_stats.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CellGroupDetailActivityStats', () {
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

    test('empty group id yields empty stats', () {
      final stats = CellGroupDetailActivityStats.compute(
        cellGroupId: '  ',
        meetings: [
          meeting(id: '1', eventDate: DateTime(2026, 8, 20), attendees: 5),
        ],
        now: now,
      );
      expect(stats.pastMeetingsCount, 0);
      expect(stats.averagePastAttendance, isNull);
    });

    test('counts only meetings linked to the group', () {
      final stats = CellGroupDetailActivityStats.compute(
        cellGroupId: 'cg1',
        meetings: [
          meeting(
            id: '1',
            eventDate: DateTime(2026, 8, 20),
            attendees: 8,
          ),
          meeting(
            id: '2',
            eventDate: DateTime(2026, 8, 10),
            attendees: 4,
          ),
          meeting(
            id: '3',
            eventDate: DateTime(2026, 8, 14),
            cellGroupIDs: ['cg2'],
            attendees: 99,
          ),
          meeting(
            id: '4',
            eventDate: DateTime(2026, 8, 22),
            attendees: 6,
          ),
        ],
        now: now,
      );

      expect(stats.pastMeetingsCount, 2);
      expect(stats.pastAttendeesTotal, 12);
      expect(stats.upcomingMeetingsCount, 1);
      expect(stats.averagePastAttendance, 6);
    });
  });
}
