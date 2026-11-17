import 'package:ctrim_app/models/event/event_head.dart';
import 'package:ctrim_app/models/event/lead_speaker.dart';
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
      int interested = 0,
      List<LeadSpeakerSnapshot> speakers = const [],
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
      head.setInterestedCount(interested);
      if (speakers.isNotEmpty) head.setLeadSpeakers(speakers);
      return head;
    }

    final locations = [
      UserLocation(id: 'p', name: 'Portadown', displayOrder: 2),
      UserLocation(id: 'b', name: 'Belfast', displayOrder: 1),
    ];

    PostTagActivitySnapshot compute(
      List<EventHead> heads, {
      String tagId = 'sunday',
      String? locationName,
    }) {
      return PostTagActivityStats.compute(
        tagId: tagId,
        now: now,
        locations: locations,
        heads: heads,
        locationName: locationName,
      );
    }

    test('window is two calendar months back through 21 days ahead', () {
      expect(
        PostTagActivityStats.rangeStartInclusive(now),
        DateTime(2026, 7, 26),
      );
      expect(
        PostTagActivityStats.pastRangeEndExclusive(now),
        DateTime(2026, 9, 26),
      );
      expect(
        PostTagActivityStats.rangeEndExclusive(now),
        DateTime(2026, 10, 17),
      );
    });

    test('splits already-held posts from today onward', () {
      final snapshot = compute([
        post(
          id: 'start',
          eventDate: DateTime(2026, 7, 26),
          attendees: 10,
          interested: 2,
          speakers: const [
            LeadSpeakerSnapshot(uid: 'alice', name: 'Alice Barr'),
          ],
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
          speakers: const [
            LeadSpeakerSnapshot(uid: 'alice', name: 'Alice Barr'),
            LeadSpeakerSnapshot(uid: 'bob', name: 'Bob Cole'),
          ],
        ),
        post(
          id: 'portadown',
          eventDate: DateTime(2026, 9, 1),
          location: 'Portadown',
          attendees: 4,
        ),
        post(
          id: 'today',
          eventDate: DateTime(2026, 9, 26, 11),
          attendees: 20,
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
        post(id: 'undated', location: 'Belfast', attendees: 8),
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
      ]);

      expect(snapshot.locations.map((row) => row.locationName), [
        'Belfast',
        'Portadown',
        'Lisburn',
      ]);
      expect(snapshot.locations[0].past.eventCount, 2);
      expect(snapshot.locations[0].past.attendanceTotal, 13);
      expect(snapshot.locations[0].past.interestedTotal, 2);
      expect(snapshot.locations[0].past.averageAttendance, 6.5);
      expect(snapshot.locations[0].upcomingEventCount, 1);
      expect(snapshot.locations[1].past.eventCount, 1);
      expect(snapshot.locations[1].past.attendanceTotal, 4);
      expect(snapshot.locations[1].upcomingEventCount, 0);
      expect(snapshot.locations[2].past.eventCount, 0);
      expect(snapshot.locations[2].past.attendanceTotal, 0);
      expect(snapshot.locations[2].upcomingEventCount, 1);

      expect(snapshot.past.eventCount, 3);
      expect(snapshot.past.attendanceTotal, 17);
      expect(snapshot.past.interestedTotal, 2);
      expect(snapshot.pastHeads.map((head) => head.id), [
        'portadown',
        'online',
        'start',
      ]);
      expect(snapshot.upcomingHeads.map((head) => head.id), [
        'today',
        'last-day',
      ]);
      expect(snapshot.speakers.map((speaker) => speaker.uid), [
        'alice',
        'bob',
      ]);
      expect(snapshot.speakers.first.appearanceCount, 2);
      expect(snapshot.speakers.last.appearanceCount, 1);
    });

    test('location filter keeps every row and limits the lists', () {
      final heads = [
        post(id: 'belfast', eventDate: DateTime(2026, 9, 1), attendees: 5),
        post(
          id: 'portadown',
          eventDate: DateTime(2026, 9, 2),
          location: 'Portadown',
          attendees: 8,
          speakers: const [LeadSpeakerSnapshot(uid: 'pat', name: 'Pat')],
        ),
        post(
          id: 'ahead',
          eventDate: DateTime(2026, 10, 1),
          location: 'Portadown',
        ),
      ];

      final snapshot = compute(heads, locationName: 'Portadown');

      expect(snapshot.locations.map((row) => row.locationName), [
        'Belfast',
        'Portadown',
      ]);
      expect(snapshot.pastHeads.map((head) => head.id), ['portadown']);
      expect(snapshot.past.attendanceTotal, 8);
      expect(snapshot.upcomingHeads.map((head) => head.id), ['ahead']);
      expect(snapshot.speakers.single.uid, 'pat');
    });

    test('an unknown location name does not hide the other sites', () {
      final snapshot = compute(
        [post(id: 'one', eventDate: DateTime(2026, 9, 1))],
        locationName: 'Lisburn',
      );

      expect(snapshot.pastHeads.single.id, 'one');
      expect(snapshot.locations.single.locationName, 'Belfast');
    });

    test('omits locations with no matching events', () {
      final snapshot = compute([
        post(id: 'one', eventDate: DateTime(2026, 9, 1), location: 'Belfast'),
      ]);

      expect(snapshot.locations.map((row) => row.locationName), ['Belfast']);
    });

    test('empty tag id yields nothing', () {
      final snapshot = compute(
        [post(id: 'one', eventDate: DateTime(2026, 9, 1))],
        tagId: '  ',
      );
      expect(snapshot.locations, isEmpty);
      expect(snapshot.pastHeads, isEmpty);
      expect(snapshot.upcomingHeads, isEmpty);
      expect(snapshot.past.eventCount, 0);
      expect(snapshot.past.averageAttendance, isNull);
    });
  });
}
