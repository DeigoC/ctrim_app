import 'package:flutter_test/flutter_test.dart';

import 'package:ctrim_app/models/event/event_head.dart';
import 'package:ctrim_app/models/user_tag.dart';
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

    UserTag tag(String id, String name, {int order = 0}) {
      return UserTag(id: id, name: name, displayOrder: order, color: '#3D6B9E');
    }

    test('each ministry is a square, and open ones come first', () {
      final soon = post(
        id: 'soon',
        title: 'Sunday',
        roles: [
          {
            'uids': <String>[],
            'title': 'Welcome',
            'tagIDs': ['welcome'],
          },
          {
            'uids': ['me'],
            'title': 'Worship',
            'tagIDs': ['worship'],
          },
        ],
      );
      final later = TeamRotaPost(
        head: head(
          id: 'later',
          title: 'Next week',
          eventDate: DateTime(2026, 10, 25),
        ),
        roles: [
          {
            'uids': ['me', 'other'],
            'title': 'Sound',
            'tagIDs': ['worship', 'tech'],
          },
        ],
      );

      final states = MinistrySchedulePreview.ministryStates(
        posts: [soon, later],
        allTags: [
          tag('worship', 'Worship', order: 2),
          tag('welcome', 'Welcome', order: 0),
          tag('tech', 'Tech', order: 1),
          tag('host', 'Host', order: 3),
        ],
        selectedTagIDs: {'worship', 'welcome', 'host'},
        viewerId: 'me',
      );

      expect(states.map((m) => m.name), ['Welcome', 'Worship', 'Host']);
      expect(states[0].openSlots, 1);
      expect(states[0].viewerIsServing, isFalse);
      expect(states[0].nextPost?.head.id, 'soon');
      expect(states[1].openSlots, 0);
      expect(states[1].viewerIsServing, isTrue);
      expect(states[1].nextPost?.head.id, 'soon');
      expect(states[2].nextPost, isNull);
    });

    test('a shared slot counts for every ministry on it', () {
      final service = post(
        id: 'p1',
        roles: [
          {
            'uids': <String>[],
            'title': 'Desk',
            'tagIDs': ['welcome', 'host'],
          },
        ],
      );

      final states = MinistrySchedulePreview.ministryStates(
        posts: [service],
        allTags: [tag('welcome', 'Welcome'), tag('host', 'Host')],
        selectedTagIDs: {'welcome', 'host'},
        viewerId: 'me',
      );

      expect(states.every((m) => m.openSlots == 1), isTrue);
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
