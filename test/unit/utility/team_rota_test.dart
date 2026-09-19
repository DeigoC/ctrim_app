import 'package:flutter_test/flutter_test.dart';

import 'package:ctrim_app/models/event/event_head.dart';
import 'package:ctrim_app/models/event/event_program.dart';
import 'package:ctrim_app/utility/catalog/volunteer_locations.dart';
import 'package:ctrim_app/utility/team_rota.dart';

void main() {
  group('TeamRotaQuery', () {
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

    EventProgram programWith(List<Map<String, dynamic>> roles) {
      final program = EventProgram();
      for (final role in roles) {
        program.addRole(
          uids: List<String>.from(role['uids'] as List? ?? const []),
          title: role['title'] as String,
          start: role['start'] as DateTime?,
          end: role['end'] as DateTime?,
          id: role['id'] as int,
          tagIDs: List<String>.from(role['tagIDs'] as List? ?? const []),
        );
      }
      return program;
    }

    final worshipSlot = <String, dynamic>{
      'uids': <String>[],
      'title': 'Worship',
      'start': DateTime(2026, 9, 20, 10),
      'end': DateTime(2026, 9, 20, 10, 30),
      'id': 1,
      'tagIDs': ['worship'],
    };
    final techSlot = <String, dynamic>{
      'uids': <String>['u1'],
      'title': 'Sound',
      'start': DateTime(2026, 9, 20, 9),
      'end': DateTime(2026, 9, 20, 12),
      'id': 2,
      'tagIDs': ['tech'],
    };
    final untaggedAssigned = <String, dynamic>{
      'uids': <String>['u-worship-person'],
      'title': 'Host',
      'start': DateTime(2026, 9, 20, 10),
      'end': DateTime(2026, 9, 20, 11),
      'id': 3,
      'tagIDs': <String>[],
    };

    test('range is start of today through N months exclusive', () {
      final now = DateTime(2026, 9, 19, 21, 15);
      expect(TeamRotaQuery.rangeStart(now), DateTime(2026, 9, 19));
      expect(
        TeamRotaQuery.rangeEndExclusive(now),
        DateTime(2026, 12, 19),
      );
      expect(
        TeamRotaQuery.rangeEndExclusive(now, months: 1),
        DateTime(2026, 10, 19),
      );
    });

    test('includes unassigned slots that carry the selected team tag', () {
      final posts = TeamRotaQuery.matchingPosts(
        posts: [
          (
            head: head(id: 'p1', eventDate: DateTime(2026, 9, 20)),
            program: programWith([worshipSlot]),
          ),
        ],
        selectedTagIDs: {'worship'},
        locationFilter: VolunteerLocations.belfast,
      );

      expect(posts, hasLength(1));
      expect(posts.single.roles.single['title'], 'Worship');
      expect(TeamRotaQuery.uidsOf(posts.single.roles.single), isEmpty);
    });

    test('omits untagged roles even when an assignee might be on that team',
        () {
      final posts = TeamRotaQuery.matchingPosts(
        posts: [
          (
            head: head(id: 'p1', eventDate: DateTime(2026, 9, 20)),
            program: programWith([untaggedAssigned, worshipSlot]),
          ),
        ],
        selectedTagIDs: {'worship'},
        locationFilter: VolunteerLocations.all,
      );

      expect(posts.single.roles.map((r) => r['title']), ['Worship']);
    });

    test('empty selected tags yields no posts', () {
      expect(
        TeamRotaQuery.matchingPosts(
          posts: [
            (
              head: head(id: 'p1', eventDate: DateTime(2026, 9, 20)),
              program: programWith([worshipSlot]),
            ),
          ],
          selectedTagIDs: const {},
          locationFilter: VolunteerLocations.all,
        ),
        isEmpty,
      );
    });

    test('filters by location and skips period parents', () {
      final posts = TeamRotaQuery.matchingPosts(
        posts: [
          (
            head: head(
              id: 'belfast',
              eventDate: DateTime(2026, 9, 20),
              location: 'Belfast',
            ),
            program: programWith([worshipSlot]),
          ),
          (
            head: head(
              id: 'portadown',
              eventDate: DateTime(2026, 9, 21),
              location: 'Portadown',
            ),
            program: programWith([worshipSlot]),
          ),
          (
            head: head(
              id: 'season',
              eventDate: DateTime(2026, 9, 22),
              isPeriodParent: true,
            ),
            program: programWith([worshipSlot]),
          ),
        ],
        selectedTagIDs: {'worship'},
        locationFilter: VolunteerLocations.belfast,
      );

      expect(posts.map((p) => p.head.id), ['belfast']);
    });

    test('sorts roles by start and posts by event date', () {
      final posts = TeamRotaQuery.matchingPosts(
        posts: [
          (
            head: head(
              id: 'later',
              eventDate: DateTime(2026, 10, 4),
              title: 'Later',
            ),
            program: programWith([worshipSlot]),
          ),
          (
            head: head(
              id: 'sooner',
              eventDate: DateTime(2026, 9, 20),
              title: 'Sooner',
            ),
            program: programWith([worshipSlot, techSlot]),
          ),
        ],
        selectedTagIDs: {'worship', 'tech'},
        locationFilter: VolunteerLocations.all,
      );

      expect(posts.map((p) => p.head.id), ['sooner', 'later']);
      expect(
        posts.first.roles.map((r) => r['title']),
        ['Sound', 'Worship'],
      );
    });

    test('groupByMonth keeps chronological month buckets', () {
      final groups = TeamRotaQuery.groupByMonth([
        TeamRotaPost(
          head: head(id: 'sep', eventDate: DateTime(2026, 9, 20)),
          roles: [worshipSlot],
        ),
        TeamRotaPost(
          head: head(id: 'oct', eventDate: DateTime(2026, 10, 4)),
          roles: [worshipSlot],
        ),
      ]);

      expect(groups, hasLength(2));
      expect(groups.first.month, 9);
      expect(groups.last.month, 10);
      expect(groups.first.posts.single.head.id, 'sep');
    });
  });
}
