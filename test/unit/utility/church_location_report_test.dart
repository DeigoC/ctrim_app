import 'package:ctrim_app/models/cell_group.dart';
import 'package:ctrim_app/models/event/event_head.dart';
import 'package:ctrim_app/models/post_tag.dart';
import 'package:ctrim_app/models/user.dart';
import 'package:ctrim_app/models/user_tag.dart';
import 'package:ctrim_app/utility/church_location_report.dart';
import 'package:ctrim_app/utility/church_location_stats.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChurchLocationReport', () {
    final now = DateTime(2026, 8, 22, 15, 30);

    User person({
      required String id,
      String location = 'Belfast',
      List<String> tagIDs = const [],
      bool isLeader = false,
      bool isAreaAdmin = false,
      bool isPlaceholder = false,
      String status = UserStatus.active,
    }) {
      return User(
        id: id,
        forname: id,
        surname: 'Person',
        location: location,
        tagIDs: tagIDs,
        isLeader: isLeader,
        isAreaAdmin: isAreaAdmin,
        isPlaceholder: isPlaceholder,
        status: status,
      );
    }

    EventHead post({
      required String id,
      required DateTime eventDate,
      String location = 'Belfast',
      List<String> tagIDs = const [],
      List<String> cellGroupIDs = const [],
      int attendance = 0,
      int interested = 0,
      bool isPeriodParent = false,
    }) {
      return EventHead(
        id: id,
        title: id,
        location: location,
        tagIDs: tagIDs,
        cellGroupIDs: cellGroupIDs,
        isPeriodParent: isPeriodParent,
      )
        ..setEventDate(eventDate)
        ..setAttendeeCount(attendance)
        ..setInterestedCount(interested);
    }

    final ministries = <UserTag>[
      UserTag(id: 'worship', name: 'Worship', color: '#112233'),
      UserTag(id: 'youth', name: 'Youth', color: '#445566'),
      UserTag(
        id: 'prayer',
        name: 'Prayer',
        visibleToGuests: false,
      ),
      UserTag(id: 'retired', name: 'Retired', isActive: false),
    ];

    final postTags = <PostTag>[
      PostTag(id: 'youth-service', name: 'Youth Service', color: '#778899'),
      PostTag(id: 'sunday', name: 'Sunday'),
      PostTag(id: 'old-series', name: 'Old series', isActive: false),
    ];

    test('empty location yields an empty report', () {
      final report = ChurchLocationReport.compute(
        location: '  ',
        users: [person(id: 'a')],
        groups: [CellGroup(id: 'g', name: 'A', location: 'Belfast')],
        heads: [post(id: 'p', eventDate: now)],
        ministries: ministries,
        postTags: postTags,
        viewerIsGuest: false,
        now: now,
      );

      expect(report.people.isEmpty, isTrue);
      expect(report.cellGroups.isEmpty, isTrue);
      expect(report.posts.isEmpty, isTrue);
    });

    test('counts a person in each ministry and once as in a ministry', () {
      final report = ChurchLocationReport.compute(
        location: 'Belfast',
        users: [
          person(id: 'both', tagIDs: ['worship', 'youth', 'worship']),
          person(id: 'worship-only', tagIDs: ['worship']),
          person(id: 'none'),
        ],
        groups: const [],
        heads: const [],
        ministries: ministries,
        postTags: const [],
        viewerIsGuest: false,
        now: now,
      );

      expect(report.people.profileCount, 3);
      expect(report.people.inMinistryCount, 2);
      expect(report.people.notInMinistryCount, 1);
      expect(
        report.people.ministries.map((row) => (row.id, row.count)),
        [('worship', 2), ('youth', 1)],
      );
      expect(report.people.ministries.first.colorHex, '#112233');
    });

    test('guests omit hidden ministries and treat them as none', () {
      final users = [
        person(id: 'hidden-only', tagIDs: ['prayer']),
        person(id: 'both', tagIDs: ['worship', 'prayer']),
      ];

      final guest = ChurchLocationReport.compute(
        location: 'Belfast',
        users: users,
        groups: const [],
        heads: const [],
        ministries: ministries,
        postTags: const [],
        viewerIsGuest: true,
        now: now,
      );
      expect(guest.people.inMinistryCount, 1);
      expect(guest.people.notInMinistryCount, 1);
      expect(guest.people.ministries.map((row) => row.id), ['worship']);

      final signedIn = ChurchLocationReport.compute(
        location: 'Belfast',
        users: users,
        groups: const [],
        heads: const [],
        ministries: ministries,
        postTags: const [],
        viewerIsGuest: false,
        now: now,
      );
      expect(signedIn.people.inMinistryCount, 2);
      expect(signedIn.people.notInMinistryCount, 0);
      expect(
        signedIn.people.ministries.map((row) => row.id),
        ['prayer', 'worship'],
      );
    });

    test(
        'skips other locations, placeholders, inactive profiles, and retired ministries',
        () {
      final users = [
        person(id: 'here', tagIDs: ['worship']),
        person(id: 'elsewhere', location: 'Portadown', tagIDs: ['worship']),
        person(id: 'placeholder', isPlaceholder: true, tagIDs: ['youth']),
        person(
          id: 'hidden',
          status: UserStatus.hidden,
          tagIDs: ['youth'],
          isLeader: true,
        ),
        person(id: 'retired-tag', tagIDs: ['retired']),
        person(id: 'admin', isAreaAdmin: true),
      ];
      final report = ChurchLocationReport.compute(
        location: 'Belfast',
        users: users,
        groups: const [],
        heads: const [],
        ministries: ministries,
        postTags: const [],
        viewerIsGuest: false,
        now: now,
      );
      final stats = ChurchLocationStats.compute(
        location: 'Belfast',
        heads: const [],
        groups: const [],
        users: users,
        now: now,
      );

      expect(report.people.profileCount, stats.peopleCount);
      expect(report.people.profileCount, 3);
      expect(report.people.inMinistryCount, 1);
      expect(report.people.notInMinistryCount, 2);
      expect(report.people.leaderCount, 1);
      expect(report.people.ministries.map((row) => row.id), ['worship']);
    });

    test('sums listed members and sorts groups largest first', () {
      final report = ChurchLocationReport.compute(
        location: 'Belfast',
        users: const [],
        groups: [
          CellGroup(
              id: 'small', name: 'Small', location: 'Belfast', memberCount: 2),
          CellGroup(
              id: 'big', name: 'Big', location: 'Belfast', memberCount: 10),
          CellGroup(
            id: 'paused',
            name: 'Paused',
            location: 'Belfast',
            memberCount: 10,
            status: CellGroupStatus.paused,
          ),
          CellGroup(
            id: 'archived',
            name: 'Archived',
            location: 'Belfast',
            memberCount: 40,
            status: CellGroupStatus.archived,
          ),
          CellGroup(
              id: 'other',
              name: 'Other',
              location: 'Portadown',
              memberCount: 9),
        ],
        heads: const [],
        ministries: const [],
        postTags: const [],
        viewerIsGuest: false,
        now: now,
      );

      expect(report.cellGroups.groupCount, 3);
      expect(report.cellGroups.membersListed, 22);
      expect(report.cellGroups.uniquePeople, isNull);
      expect(report.cellGroups.averageSize, 22 / 3);
      expect(
        report.cellGroups.groups.map((row) => (row.id, row.count)),
        [('big', 10), ('paused', 10), ('small', 2)],
      );
    });

    test('splits meetings from other posts and averages attendance', () {
      final heads = [
        post(
          id: 'meeting',
          eventDate: DateTime(2026, 8, 20),
          tagIDs: ['youth-service', 'sunday', 'youth-service'],
          cellGroupIDs: ['cg1'],
          attendance: 10,
          interested: 4,
        ),
        post(
          id: 'plain',
          eventDate: DateTime(2026, 8, 18),
          attendance: 0,
          interested: 1,
        ),
        post(
          id: 'retired-tag',
          eventDate: DateTime(2026, 8, 10),
          tagIDs: ['old-series'],
          attendance: 2,
        ),
        post(
          id: 'online',
          eventDate: DateTime(2026, 8, 1),
          location: 'Belfast (Online)',
          tagIDs: ['youth-service'],
          attendance: 8,
        ),
        post(id: 'old', eventDate: DateTime(2026, 5, 1), attendance: 99),
        post(
          id: 'elsewhere',
          eventDate: DateTime(2026, 8, 15),
          location: 'Portadown',
          attendance: 50,
        ),
        post(
          id: 'series',
          eventDate: DateTime(2026, 8, 12),
          isPeriodParent: true,
          attendance: 30,
        ),
      ];

      final report = ChurchLocationReport.compute(
        location: 'Belfast',
        users: const [],
        groups: const [],
        heads: heads,
        ministries: const [],
        postTags: postTags,
        viewerIsGuest: true,
        now: now,
      );

      expect(report.posts.postCount, 4);
      expect(report.posts.cellGroupMeetingCount, 1);
      expect(report.posts.otherPostCount, 3);
      expect(report.posts.attendanceTotal, 20);
      expect(report.posts.averageAttendance, 5);
      expect(report.posts.interestedTotal, 5);
      expect(
        report.posts.tags.map((row) => (row.id, row.count)),
        [
          ('youth-service', 2),
          ('sunday', 1),
          (ChurchLocationReport.untaggedPostId, 2),
        ],
      );
      expect(report.posts.posts.map((head) => head.id), [
        'meeting',
        'plain',
        'retired-tag',
        'online',
      ]);
      expect(report.posts.upcoming.postCount, 0);
    });

    test('counts a person on two group rosters once', () {
      final report = ChurchLocationReport.compute(
        location: 'Belfast',
        users: const [],
        groups: [
          CellGroup(
              id: 'a', name: 'North', location: 'Belfast', memberCount: 2),
          CellGroup(
              id: 'b', name: 'South', location: 'Belfast', memberCount: 2),
        ],
        heads: const [],
        ministries: const [],
        postTags: const [],
        viewerIsGuest: false,
        rosterUserIdsByGroup: const [
          ['ada', 'ben', ''],
          ['ben', '  ', 'cio'],
        ],
        now: now,
      );

      expect(report.cellGroups.membersListed, 4);
      expect(report.cellGroups.uniquePeople, 3);
    });

    test('upcoming posts stay out of the attendance average', () {
      final today = post(
        id: 'today',
        eventDate: DateTime(2026, 8, 22, 11),
        attendance: 4,
        cellGroupIDs: ['cg'],
      );
      final past = post(
        id: 'past',
        eventDate: DateTime(2026, 8, 1),
        attendance: 6,
      );
      final soon = post(
        id: 'soon',
        eventDate: DateTime(2026, 8, 25),
        attendance: 100,
        cellGroupIDs: ['cg'],
      );

      final report = ChurchLocationReport.compute(
        location: 'Belfast',
        users: const [],
        groups: const [],
        heads: [
          today,
          past,
          soon,
          post(
            id: 'series',
            eventDate: DateTime(2026, 8, 24),
            isPeriodParent: true,
            attendance: 50,
          ),
        ],
        upcomingHeads: [
          today,
          soon,
          post(
            id: 'too-far',
            eventDate: DateTime(2026, 8, 29),
            attendance: 9,
          ),
          post(
            id: 'elsewhere',
            eventDate: DateTime(2026, 8, 24),
            location: 'Portadown',
            attendance: 3,
          ),
          post(
            id: 'series-upcoming',
            eventDate: DateTime(2026, 8, 24),
            isPeriodParent: true,
          ),
        ],
        ministries: const [],
        postTags: const [],
        viewerIsGuest: true,
        now: now,
      );

      expect(report.posts.postCount, 2);
      expect(report.posts.attendanceTotal, 10);
      expect(report.posts.averageAttendance, 5);
      expect(report.posts.posts.map((head) => head.id), ['today', 'past']);
      expect(report.posts.upcoming.postCount, 2);
      expect(report.posts.upcoming.cellGroupMeetingCount, 2);
      expect(report.posts.upcoming.otherPostCount, 0);
    });
  });
}
