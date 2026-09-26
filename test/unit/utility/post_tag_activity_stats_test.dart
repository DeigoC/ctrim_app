import 'package:ctrim_app/models/event/event_head.dart';
import 'package:ctrim_app/models/user_location.dart';
import 'package:ctrim_app/utility/post_tag_activity_stats.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PostTagActivityStats', () {
    final now = DateTime(2026, 9, 26, 15, 30);

    EventHead post({
      required String id,
      DateTime? eventDate,
      String location = 'Belfast',
      List<String> tagIDs = const ['sunday'],
      bool isPeriodParent = false,
      int attendees = 0,
    }) {
      final head = EventHead(
        id: id,
        title: id,
        location: location,
        tagIDs: tagIDs,
        isPeriodParent: isPeriodParent,
      );
      if (eventDate != null) head.setEventDate(eventDate);
      head.setAttendeeCount(attendees);
      return head;
    }

    final locations = [
      UserLocation(id: 'p', name: 'Portadown', displayOrder: 2),
      UserLocation(id: 'b', name: 'Belfast', displayOrder: 1),
    ];

    test('window is two calendar months back through 21 days ahead', () {
      expect(
        PostTagActivityStats.rangeStartInclusive(now),
        DateTime(2026, 7, 26),
      );
      expect(
        PostTagActivityStats.rangeEndExclusive(now),
        DateTime(2026, 10, 17),
      );
    });

    test('groups dated posts by location and sums attendance', () {
      final rows = PostTagActivityStats.byLocation(
        tagId: 'sunday',
        now: now,
        locations: locations,
        heads: [
          post(
            id: 'start',
            eventDate: DateTime(2026, 7, 26),
            attendees: 10,
          ),
          post(
            id: 'before',
            eventDate: DateTime(2026, 7, 25, 23, 59),
            attendees: 99,
          ),
          post(
            id: 'online',
            eventDate: DateTime(2026, 8, 2),
            location: 'Belfast (Online)',
            attendees: 3,
          ),
          post(
            id: 'portadown',
            eventDate: DateTime(2026, 9, 1),
            location: 'Portadown',
            attendees: 4,
          ),
          post(
            id: 'last-day',
            eventDate: DateTime(2026, 10, 16, 23),
            location: 'Lisburn',
            attendees: 2,
          ),
          post(
            id: 'after',
            eventDate: DateTime(2026, 10, 17),
            location: 'Lisburn',
            attendees: 50,
          ),
          post(
            id: 'undated',
            location: 'Belfast',
            attendees: 8,
          ),
          post(
            id: 'series',
            eventDate: DateTime(2026, 9, 10),
            isPeriodParent: true,
            attendees: 40,
          ),
          post(
            id: 'other-tag',
            eventDate: DateTime(2026, 9, 10),
            tagIDs: const ['youth'],
            attendees: 7,
          ),
          post(
            id: 'blank-location',
            eventDate: DateTime(2026, 9, 10),
            location: '   ',
            attendees: 6,
          ),
        ],
      );

      expect(rows.map((row) => row.locationName), [
        'Belfast',
        'Portadown',
        'Lisburn',
      ]);
      expect(rows[0].eventCount, 2);
      expect(rows[0].attendanceTotal, 13);
      expect(rows[1].eventCount, 1);
      expect(rows[1].attendanceTotal, 4);
      expect(rows[2].eventCount, 1);
      expect(rows[2].attendanceTotal, 2);
    });

    test('omits locations with no matching events', () {
      final rows = PostTagActivityStats.byLocation(
        tagId: 'sunday',
        now: now,
        locations: locations,
        heads: [
          post(
            id: 'one',
            eventDate: DateTime(2026, 9, 1),
            location: 'Belfast',
          ),
        ],
      );

      expect(rows.map((row) => row.locationName), ['Belfast']);
    });

    test('empty tag id yields no rows', () {
      final rows = PostTagActivityStats.byLocation(
        tagId: '  ',
        now: now,
        locations: locations,
        heads: [
          post(id: 'one', eventDate: DateTime(2026, 9, 1)),
        ],
      );
      expect(rows, isEmpty);
    });
  });
}
