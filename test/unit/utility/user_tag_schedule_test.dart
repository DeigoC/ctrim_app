import 'package:ctrim_app/models/event/event_head.dart';
import 'package:ctrim_app/models/event/event_program.dart';
import 'package:ctrim_app/utility/user_tag_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserTagScheduleQuery', () {
    final now = DateTime(2026, 9, 23, 21, 15);

    EventHead head({
      required String id,
      required DateTime eventDate,
      String location = 'Belfast',
      String title = 'Sunday',
    }) {
      final result = EventHead(id: id, title: title, location: location);
      result.setEventDate(eventDate);
      return result;
    }

    EventProgram programWith({
      required String title,
      required int id,
      bool forGuests = true,
      List<String> tagIDs = const ['worship'],
    }) {
      final program = EventProgram();
      program.addRole(
        uids: const ['u1'],
        title: title,
        start: DateTime(2026, 9, 23, 10),
        end: DateTime(2026, 9, 23, 11),
        id: id,
        forGuests: forGuests,
        tagIDs: tagIDs,
      );
      return program;
    }

    test('window is three months back through three months ahead', () {
      expect(
        UserTagScheduleQuery.rangeStartInclusive(now),
        DateTime(2026, 6, 23),
      );
      expect(
        UserTagScheduleQuery.rangeEndExclusive(now),
        DateTime(2026, 12, 23),
      );
    });

    test('splits today into upcoming and older dates into past, newest first',
        () {
      final posts = [
        (
          head: head(
              id: 'today', eventDate: DateTime(2026, 9, 23), title: 'Today'),
          program: programWith(title: 'Worship', id: 1),
        ),
        (
          head: head(
            id: 'older',
            eventDate: DateTime(2026, 8, 1),
            title: 'August',
          ),
          program: programWith(title: 'Worship', id: 2),
        ),
        (
          head: head(
            id: 'newer-past',
            eventDate: DateTime(2026, 9, 1),
            title: 'September',
          ),
          program: programWith(title: 'Worship', id: 3),
        ),
        (
          head: head(
            id: 'future',
            eventDate: DateTime(2026, 10, 4),
            title: 'October',
          ),
          program: programWith(title: 'Worship', id: 4),
        ),
        (
          head: head(
            id: 'other-site',
            eventDate: DateTime(2026, 10, 5),
            location: 'Portadown',
          ),
          program: programWith(title: 'Worship', id: 5),
        ),
        (
          head: head(id: 'other-team', eventDate: DateTime(2026, 10, 6)),
          program: programWith(title: 'Sound', id: 6, tagIDs: const ['tech']),
        ),
      ];

      final split = UserTagScheduleQuery.split(
        posts: posts,
        tagId: 'worship',
        locationName: 'Belfast',
        now: now,
      );

      expect(split.upcoming.map((post) => post.head.id), ['today', 'future']);
      expect(
        split.past.map((post) => post.head.id),
        ['newer-past', 'older'],
      );
    });

    test('guests only see roles marked for guests', () {
      final publicProgram = EventProgram()
        ..addRole(
          uids: const ['u1'],
          title: 'Worship',
          start: DateTime(2026, 10, 4, 10),
          end: DateTime(2026, 10, 4, 11),
          id: 1,
          forGuests: true,
          tagIDs: const ['worship'],
        )
        ..addRole(
          uids: const ['u2'],
          title: 'Sound check',
          start: DateTime(2026, 10, 4, 9),
          end: DateTime(2026, 10, 4, 9, 30),
          id: 2,
          forGuests: false,
          tagIDs: const ['worship'],
        );
      final staffOnly = EventProgram()
        ..addRole(
          uids: const ['u3'],
          title: 'Rehearsal',
          start: DateTime(2026, 10, 5, 18),
          end: DateTime(2026, 10, 5, 20),
          id: 3,
          forGuests: false,
          tagIDs: const ['worship'],
        );

      final split = UserTagScheduleQuery.split(
        posts: [
          (
            head: head(id: 'mixed', eventDate: DateTime(2026, 10, 4)),
            program: publicProgram,
          ),
          (
            head: head(id: 'staff', eventDate: DateTime(2026, 10, 5)),
            program: staffOnly,
          ),
        ],
        tagId: 'worship',
        locationName: 'Belfast',
        now: now,
        guestsOnly: true,
      );

      expect(split.upcoming.map((post) => post.head.id), ['mixed']);
      expect(split.upcoming.single.roles.map((role) => role['title']),
          ['Worship']);
      expect(split.past, isEmpty);
    });
  });
}
