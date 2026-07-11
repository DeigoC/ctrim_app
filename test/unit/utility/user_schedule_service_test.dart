import 'package:flutter_test/flutter_test.dart';

import 'package:ctrim_app/models/event/event_head.dart';
import 'package:ctrim_app/models/user.dart';
import 'package:ctrim_app/models/user_post_involvement.dart';
import 'package:ctrim_app/models/user_role_assignment.dart';
import 'package:ctrim_app/utility/user_schedule_service.dart';

void main() {
  group('UserScheduleService', () {
    final assignment = UserRoleAssignment(
      postID: 'post-1',
      roleID: 1,
      start: DateTime(2024, 6, 15, 10),
      end: DateTime(2024, 6, 15, 11),
      title: 'Setup',
    );

    EventHead headWithDate(String id, DateTime eventDate) {
      final head = EventHead(id: id, title: 'Event');
      head.setEventDate(eventDate);
      return head;
    }

    group('staleRolePostIDs', () {
      test('returns empty when roles are not loaded', () {
        final user = User(id: '1', forname: 'John', surname: 'Smith');

        expect(
          UserScheduleService.staleRolePostIDs(user: user, eventHeads: []),
          isEmpty,
        );
      });

      test('includes roles for posts missing from event heads', () {
        final user = User(id: '1', forname: 'John', surname: 'Smith')..setRoles([assignment]);

        expect(
          UserScheduleService.staleRolePostIDs(user: user, eventHeads: []),
          ['post-1'],
        );
      });

      test('includes roles for events more than one day in the past', () {
        final user = User(id: '1', forname: 'John', surname: 'Smith')..setRoles([assignment]);
        final heads = [headWithDate('post-1', DateTime(2024, 1, 1))];
        final now = DateTime(2024, 1, 3);

        expect(
          UserScheduleService.staleRolePostIDs(user: user, eventHeads: heads, now: now),
          ['post-1'],
        );
      });

      test('keeps roles for upcoming events', () {
        final user = User(id: '1', forname: 'John', surname: 'Smith')..setRoles([assignment]);
        final heads = [headWithDate('post-1', DateTime(2024, 6, 20))];
        final now = DateTime(2024, 6, 15);

        expect(
          UserScheduleService.staleRolePostIDs(user: user, eventHeads: heads, now: now),
          isEmpty,
        );
      });

      test('deduplicates multiple roles on the same stale post', () {
        final user = User(id: '1', forname: 'John', surname: 'Smith')
          ..setRoles([
            assignment,
            UserRoleAssignment(
              postID: 'post-1',
              roleID: 2,
              start: DateTime(2024, 6, 15, 12),
              end: DateTime(2024, 6, 15, 13),
              title: 'Teardown',
            ),
          ]);

        expect(
          UserScheduleService.staleRolePostIDs(user: user, eventHeads: []),
          ['post-1'],
        );
      });
    });

    group('stalePostInvolvementIDs', () {
      test('returns empty when posts are not loaded', () {
        final user = User(id: '1', forname: 'John', surname: 'Smith');

        expect(
          UserScheduleService.stalePostInvolvementIDs(user: user, eventHeads: []),
          isEmpty,
        );
      });

      test('includes posts missing from event heads', () {
        final user = User(id: '1', forname: 'John', surname: 'Smith')
          ..setPosts([
            UserPostInvolvement(postID: 'post-1', ownership: PostOwnership.author),
            UserPostInvolvement(postID: 'post-2', ownership: PostOwnership.contributor),
          ]);
        final heads = [headWithDate('post-2', DateTime(2024, 6, 20))];

        expect(
          UserScheduleService.stalePostInvolvementIDs(user: user, eventHeads: heads),
          ['post-1'],
        );
      });

      test('returns empty when all posts have matching heads', () {
        final user = User(id: '1', forname: 'John', surname: 'Smith')
          ..setPosts([
            UserPostInvolvement(postID: 'post-1', ownership: PostOwnership.author),
          ]);
        final heads = [headWithDate('post-1', DateTime(2024, 6, 20))];

        expect(
          UserScheduleService.stalePostInvolvementIDs(user: user, eventHeads: heads),
          isEmpty,
        );
      });
    });
    group('upcomingRoles and upcomingPostCount', () {
      test('upcomingRoles excludes stale assignments and respects limit', () {
        final user = User(id: '1', forname: 'John', surname: 'Smith')
          ..setRoles([
            UserRoleAssignment(
              postID: 'past-post',
              roleID: 1,
              start: DateTime(2024, 1, 1, 10),
              end: DateTime(2024, 1, 1, 11),
              title: 'Past',
            ),
            UserRoleAssignment(
              postID: 'future-post',
              roleID: 2,
              start: DateTime(2024, 6, 20, 10),
              end: DateTime(2024, 6, 20, 11),
              title: 'Future',
            ),
            UserRoleAssignment(
              postID: 'future-post',
              roleID: 3,
              start: DateTime(2024, 6, 20, 12),
              end: DateTime(2024, 6, 20, 13),
              title: 'Future 2',
            ),
          ]);
        final heads = [headWithDate('past-post', DateTime(2024, 1, 1)), headWithDate('future-post', DateTime(2024, 6, 20))];
        final now = DateTime(2024, 6, 15);

        expect(
          UserScheduleService.upcomingRoles(user: user, eventHeads: heads, now: now, limit: 1).length,
          1,
        );
        expect(
          UserScheduleService.upcomingRoles(user: user, eventHeads: heads, now: now).map((e) => e.title).toList(),
          ['Future', 'Future 2'],
        );
      });

      test('upcomingPostCount counts distinct upcoming posts only', () {
        final user = User(id: '1', forname: 'John', surname: 'Smith')
          ..setRoles([
            UserRoleAssignment(
              postID: 'future-post',
              roleID: 1,
              start: DateTime(2024, 6, 20, 10),
              end: DateTime(2024, 6, 20, 11),
              title: 'A',
            ),
            UserRoleAssignment(
              postID: 'future-post',
              roleID: 2,
              start: DateTime(2024, 6, 20, 12),
              end: DateTime(2024, 6, 20, 13),
              title: 'B',
            ),
            UserRoleAssignment(
              postID: 'orphan-post',
              roleID: 3,
              start: DateTime(2024, 6, 21, 10),
              end: DateTime(2024, 6, 21, 11),
              title: 'C',
            ),
          ]);
        final heads = [headWithDate('future-post', DateTime(2024, 6, 20))];
        final now = DateTime(2024, 6, 15);

        expect(
          UserScheduleService.upcomingPostCount(user: user, eventHeads: heads, now: now),
          1,
        );
      });
    });
  });
}
