import 'package:flutter_test/flutter_test.dart';

import 'package:ctrim_app/models/event/event_head.dart';
import 'package:ctrim_app/models/event/event_program.dart';
import 'package:ctrim_app/models/user.dart';
import 'package:ctrim_app/models/user_tag.dart';
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

    test('empty selected tags shows all tagged roles', () {
      final posts = TeamRotaQuery.matchingPosts(
        posts: [
          (
            head: head(id: 'p1', eventDate: DateTime(2026, 9, 20)),
            program: programWith([untaggedAssigned, worshipSlot, techSlot]),
          ),
        ],
        selectedTagIDs: const {},
        locationFilter: VolunteerLocations.all,
      );

      expect(posts, hasLength(1));
      expect(
        posts.single.roles.map((r) => r['title']),
        ['Sound', 'Worship'],
      );
    });

    test('selected tags narrow to matching ministries only', () {
      final posts = TeamRotaQuery.matchingPosts(
        posts: [
          (
            head: head(id: 'p1', eventDate: DateTime(2026, 9, 20)),
            program: programWith([worshipSlot, techSlot]),
          ),
        ],
        selectedTagIDs: {'worship'},
        locationFilter: VolunteerLocations.all,
      );

      expect(posts.single.roles.map((r) => r['title']), ['Worship']);
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

    test('visibleRoleCount keeps short lists open and previews long ones', () {
      expect(
        TeamRotaQuery.visibleRoleCount(total: 5, expanded: false),
        5,
      );
      expect(
        TeamRotaQuery.visibleRoleCount(total: 6, expanded: false),
        TeamRotaQuery.previewRoleCount,
      );
      expect(
        TeamRotaQuery.visibleRoleCount(total: 12, expanded: true),
        12,
      );
    });

    User person({
      required String id,
      bool isAreaAdmin = false,
      bool isLeader = false,
      List<String> tagIDs = const [],
    }) {
      return User(
        id: id,
        forname: 'Ada',
        surname: 'Lane',
        isAreaAdmin: isAreaAdmin,
        isLeader: isLeader,
        tagIDs: tagIDs,
      );
    }

    UserTag ministry({
      required String id,
      Map<String, List<String>> headsByLocation = const {},
      bool isActive = true,
    }) {
      return UserTag(
        id: id,
        name: id,
        isActive: isActive,
        headsByLocation: headsByLocation,
      );
    }

    Map<String, dynamic> slot({
      required int id,
      required List<String> tagIDs,
      List<String> uids = const [],
      DateTime? start,
    }) {
      return {
        'id': id,
        'title': 'Slot',
        'uids': uids,
        'tagIDs': tagIDs,
        'start': start,
        'end': start?.add(const Duration(hours: 1)),
      };
    }

    final now = DateTime(2026, 9, 20, 9);
    final later = DateTime(2026, 9, 20, 11);
    final earlier = DateTime(2026, 9, 20, 8);
    final eventDay = DateTime(2026, 9, 20, 10, 30);

    test('area admin can assign a tagged slot that has not started', () {
      expect(
        TeamRotaQuery.canAssignRole(
          actor: person(id: 'admin', isAreaAdmin: true),
          role: slot(id: 1, tagIDs: ['worship'], start: later),
          eventDate: eventDay,
          locationId: 'belfast',
          allTags: [ministry(id: 'worship')],
          now: now,
        ),
        isTrue,
      );
    });

    test('a started slot is locked for an area admin', () {
      expect(
        TeamRotaQuery.canAssignRole(
          actor: person(id: 'admin', isAreaAdmin: true),
          role: slot(id: 1, tagIDs: ['worship'], start: earlier),
          eventDate: eventDay,
          locationId: 'belfast',
          allTags: [ministry(id: 'worship')],
          now: now,
        ),
        isFalse,
      );
    });

    test('ministry head at the post church can assign that slot', () {
      expect(
        TeamRotaQuery.canAssignRole(
          actor: person(id: 'head'),
          role: slot(id: 1, tagIDs: ['worship'], start: later),
          eventDate: eventDay,
          locationId: 'belfast',
          allTags: [
            ministry(
              id: 'worship',
              headsByLocation: {
                'belfast': ['head'],
              },
            ),
          ],
          now: now,
        ),
        isTrue,
      );
    });

    test('head of a different ministry cannot assign the slot', () {
      expect(
        TeamRotaQuery.canAssignRole(
          actor: person(id: 'head', isLeader: true),
          role: slot(id: 1, tagIDs: ['worship'], start: later),
          eventDate: eventDay,
          locationId: 'belfast',
          allTags: [
            ministry(id: 'worship'),
            ministry(
              id: 'welcome',
              headsByLocation: {
                'belfast': ['head'],
              },
            ),
          ],
          now: now,
        ),
        isFalse,
      );
    });

    test('a member who is not a head cannot assign', () {
      expect(
        TeamRotaQuery.canAssignRole(
          actor: person(id: 'member', tagIDs: ['worship']),
          role: slot(id: 1, tagIDs: ['worship'], start: later),
          eventDate: eventDay,
          locationId: 'belfast',
          allTags: [
            ministry(
              id: 'worship',
              headsByLocation: {
                'belfast': ['someone-else'],
              },
            ),
          ],
          now: now,
        ),
        isFalse,
      );
    });

    test('a head of one ministry on a shared slot can assign it', () {
      expect(
        TeamRotaQuery.canAssignRole(
          actor: person(id: 'media-head'),
          role: slot(
            id: 1,
            tagIDs: ['worship', 'media'],
            start: later,
          ),
          eventDate: eventDay,
          locationId: 'belfast',
          allTags: [
            ministry(id: 'worship'),
            ministry(
              id: 'media',
              headsByLocation: {
                'belfast': ['media-head'],
              },
            ),
          ],
          now: now,
        ),
        isTrue,
      );
    });

    test('an untimed slot locks after its calendar day', () {
      final role = slot(id: 1, tagIDs: ['worship']);
      expect(
        TeamRotaQuery.canAssignRole(
          actor: person(id: 'admin', isAreaAdmin: true),
          role: role,
          eventDate: eventDay,
          locationId: 'belfast',
          allTags: [ministry(id: 'worship')],
          now: now,
        ),
        isTrue,
      );
      expect(
        TeamRotaQuery.canAssignRole(
          actor: person(id: 'admin', isAreaAdmin: true),
          role: role,
          eventDate: eventDay,
          locationId: 'belfast',
          allTags: [ministry(id: 'worship')],
          now: DateTime(2026, 9, 21, 8),
        ),
        isFalse,
      );
    });

    test('opening ministries include membership and headship at that church',
        () {
      final ids = TeamRotaQuery.openingMinistryIds(
        user: person(id: 'head', tagIDs: ['welcome']),
        allTags: [
          ministry(id: 'welcome'),
          ministry(
            id: 'worship',
            headsByLocation: {
              'belfast': ['head'],
            },
          ),
          ministry(
            id: 'media',
            headsByLocation: {
              'portadown': ['head'],
            },
          ),
          ministry(
            id: 'paused',
            isActive: false,
            headsByLocation: {
              'belfast': ['head'],
            },
          ),
        ],
        locationId: 'belfast',
      );

      expect(ids, {'welcome', 'worship'});
    });

    test('gap count and needs-people keep only empty slots', () {
      final posts = TeamRotaQuery.matchingPosts(
        posts: [
          (
            head: head(id: 'p1', eventDate: DateTime(2026, 9, 20)),
            program: programWith([
              worshipSlot,
              techSlot,
              {
                'uids': <String>[],
                'title': 'Welcome',
                'start': DateTime(2026, 9, 20, 10, 30),
                'end': DateTime(2026, 9, 20, 11),
                'id': 4,
                'tagIDs': ['welcome'],
              },
            ]),
          ),
          (
            head: head(id: 'p2', eventDate: DateTime(2026, 9, 27)),
            program: programWith([techSlot]),
          ),
        ],
        selectedTagIDs: const {},
        locationFilter: VolunteerLocations.all,
      );

      expect(TeamRotaQuery.unassignedRoleCount(posts), 2);
      final gaps = TeamRotaQuery.postsNeedingPeople(posts);
      expect(gaps.map((post) => post.head.id), ['p1']);
      expect(gaps.single.roles.map((role) => role['title']),
          ['Worship', 'Welcome']);
    });

    test('sameAssigneeIds ignores order', () {
      expect(TeamRotaQuery.sameAssigneeIds(['a', 'b'], ['b', 'a']), isTrue);
      expect(TeamRotaQuery.sameAssigneeIds(['a'], ['a', 'b']), isFalse);
    });
  });
}
