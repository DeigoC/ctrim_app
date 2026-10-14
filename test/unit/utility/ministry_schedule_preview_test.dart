import 'package:flutter_test/flutter_test.dart';

import 'package:ctrim_app/models/event/event_head.dart';
import 'package:ctrim_app/utility/catalog/volunteer_locations.dart';
import 'package:ctrim_app/utility/ministry_schedule_preview.dart';
import 'package:ctrim_app/utility/team_rota.dart';

void main() {
  group('MinistrySchedulePreview', () {
    EventHead head({
      required String id,
      DateTime? eventDate,
      String location = 'Belfast',
      bool isPeriodParent = false,
      String title = 'Sunday',
    }) {
      final result = EventHead(
        id: id,
        title: title,
        location: location,
        isPeriodParent: isPeriodParent,
      );
      if (eventDate != null) result.setEventDate(eventDate);
      return result;
    }

    TeamRotaPost post({
      required String id,
      required List<Map<String, dynamic>> roles,
      String title = 'Sunday',
    }) {
      return TeamRotaPost(
        head: head(id: id, title: title, eventDate: DateTime(2026, 10, 18)),
        roles: roles,
      );
    }

    test('programme reads keep the soonest posts at the location', () {
      final heads = [
        head(id: 'later', eventDate: DateTime(2026, 10, 25), title: 'Later'),
        head(
          id: 'other',
          eventDate: DateTime(2026, 10, 18),
          location: 'Portadown',
        ),
        head(
            id: 'parent',
            eventDate: DateTime(2026, 10, 11),
            isPeriodParent: true),
        head(id: 'soon', eventDate: DateTime(2026, 10, 18), title: 'Soon'),
      ];

      final reads = MinistrySchedulePreview.headsForProgrammeReads(
        heads: heads,
        locationFilter: VolunteerLocations.belfast,
      );

      expect(reads.map((h) => h.id), ['soon', 'later']);
    });

    test('programme reads stop after the cap, soonest first', () {
      final heads = [
        for (var day = 1; day <= 10; day++)
          head(
            id: 'd$day',
            eventDate: DateTime(2026, 10, day),
            title: 'Day $day',
          ),
      ];

      final reads = MinistrySchedulePreview.headsForProgrammeReads(
        heads: heads,
        locationFilter: VolunteerLocations.belfast,
        cap: 8,
      );

      expect(reads, hasLength(8));
      expect(reads.first.id, 'd1');
      expect(reads.last.id, 'd8');
    });

    test('the card shows the first three services', () {
      final posts = [
        for (var i = 0; i < 5; i++)
          post(id: 'p$i', roles: const [], title: 'Service $i'),
      ];

      final visible = MinistrySchedulePreview.visiblePosts(posts);

      expect(visible.map((p) => p.head.id), ['p0', 'p1', 'p2']);
    });

    test('assignee ids follow role order and skip repeats', () {
      final service = post(
        id: 'p1',
        roles: [
          {
            'uids': ['a', 'b'],
            'title': 'Welcome',
          },
          {
            'uids': ['b', 'c'],
            'title': 'Sound',
          },
          {
            'uids': <String>[],
            'title': 'Host',
          },
        ],
      );

      expect(
        MinistrySchedulePreview.assigneeIds(service),
        ['a', 'b', 'c'],
      );
    });
  });
}
