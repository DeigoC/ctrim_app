import 'dart:math';

import 'package:ctrim_app/models/event/event_attendance.dart';
import 'package:ctrim_app/models/user.dart';
import 'package:ctrim_app/utility/post_title_attendees.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PostTitleAttendees.shortenedFromDisplayName', () {
    test('uses forename and surname initial', () {
      expect(
        PostTitleAttendees.shortenedFromDisplayName('Jane Doe'),
        'Jane D.',
      );
    });

    test('keeps each initial of a hyphenated surname', () {
      expect(
        PostTitleAttendees.shortenedFromDisplayName('Ann Smith-Jones'),
        'Ann SJ.',
      );
    });

    test('keeps a single-word name', () {
      expect(PostTitleAttendees.shortenedFromDisplayName('Madonna'), 'Madonna');
    });

    test('keeps a multi-word forename', () {
      expect(
        PostTitleAttendees.shortenedFromDisplayName('Mary Anne Smith'),
        'Mary Anne S.',
      );
    });
  });

  group('PostTitleAttendees.shortenedNames', () {
    test('uses the profile short name, including opted-in full surnames', () {
      final user = User(
        id: 'u1',
        forname: 'John',
        surname: 'Doe',
        showFullSurnameToGuests: true,
      );
      final attendees = [
        AttendeeEntry.user(
          userId: 'u1',
          displayName: 'John Doe',
          addedBy: 'editor',
        ),
      ];

      expect(
        PostTitleAttendees.shortenedNames(attendees, (id) => user),
        ['John D.'],
      );
    });

    test('shortens a stored display name when the profile is missing', () {
      final attendees = [
        AttendeeEntry.user(
          userId: 'missing',
          displayName: 'Mary Smith',
          addedBy: 'editor',
        ),
        AttendeeEntry.external(name: 'Ann Smith-Jones', addedBy: 'editor'),
      ];

      expect(
        PostTitleAttendees.shortenedNames(attendees, (_) => null),
        ['Mary S.', 'Ann SJ.'],
      );
    });

    test('skips blank names', () {
      final user = User(id: 'u1', forname: '', surname: '');
      final attendees = [
        AttendeeEntry.user(userId: 'u1', displayName: '', addedBy: 'editor'),
        AttendeeEntry.external(name: '   ', addedBy: 'editor'),
      ];

      expect(
        PostTitleAttendees.shortenedNames(attendees, (_) => user),
        isEmpty,
      );
    });
  });

  group('PostTitleAttendees.appendOrderedNames', () {
    test('appends every name when they fit', () {
      expect(
        PostTitleAttendees.appendOrderedNames(
          title: 'Group',
          orderedNames: ['Ann A.', 'Bob B.', 'Cara C.'],
        ),
        'Group w/ Ann A., Bob B., Cara C.',
      );
    });

    test('stops before 64 characters and counts the rest', () {
      expect(
        PostTitleAttendees.appendOrderedNames(
          title: "Diego's Cell group",
          orderedNames: [
            'Ann A.',
            'Bob B.',
            'Cara C.',
            'Dan D.',
            'Eve E.',
            'Fay F.',
            'Gil G.',
            'Hal H.',
          ],
        ),
        "Diego's Cell group w/ Ann A., Bob B., Cara C., Dan D., Eve E. +3",
      );
      expect(
        "Diego's Cell group w/ Ann A., Bob B., Cara C., Dan D., Eve E. +3"
            .length,
        lessThanOrEqualTo(PostTitleAttendees.maxLength),
      );
    });

    test('does not list a name when the extra-count will not fit', () {
      final stem = 'S' * 54;
      expect(
        PostTitleAttendees.appendOrderedNames(
          title: stem,
          orderedNames: ['Ann A.', 'Bob B.'],
        ),
        isNull,
      );
    });

    test('leaves the title alone when the stem already fills the limit', () {
      expect(
        PostTitleAttendees.appendOrderedNames(
          title: 'T' * PostTitleAttendees.maxLength,
          orderedNames: ['Ann A.'],
        ),
        isNull,
      );
    });

    test('replaces a previous attendance ending', () {
      expect(
        PostTitleAttendees.appendOrderedNames(
          title: "Diego's Cell group w/ Zoe Z., Yan Y. +4",
          orderedNames: ['Ann A.', 'Bob B.'],
        ),
        "Diego's Cell group w/ Ann A., Bob B.",
      );
    });

    test('keeps a hand-written with-phrase that is not an attendance list', () {
      expect(
        PostTitleAttendees.appendOrderedNames(
          title: 'Bible study w/ Romans',
          orderedNames: ['Ann A.'],
        ),
        'Bible study w/ Romans w/ Ann A.',
      );
    });

    test('returns null when there are no usable names', () {
      expect(
        PostTitleAttendees.appendOrderedNames(
          title: 'Group',
          orderedNames: ['?', '  '],
        ),
        isNull,
      );
    });
  });

  group('PostTitleAttendees.resolveNewCellGroupTitle', () {
    const names = ['Ann A.', 'Bob B.'];

    test('appends attendees when the cell-group title is still the default',
        () {
      final title = PostTitleAttendees.resolveNewCellGroupTitle(
        title: "Diego's Cell group",
        defaultTitle: "Diego's Cell group",
        linkedToCellGroup: true,
        shortenedNames: names,
        random: Random(1),
      );

      expect(title, startsWith("Diego's Cell group w/ "));
      expect(title, contains('Ann A.'));
      expect(title, contains('Bob B.'));
    });

    test('leaves a title the organiser has edited', () {
      expect(
        PostTitleAttendees.resolveNewCellGroupTitle(
          title: 'Tuesday night',
          defaultTitle: "Diego's Cell group",
          linkedToCellGroup: true,
          shortenedNames: names,
          random: Random(1),
        ),
        'Tuesday night',
      );
    });

    test('leaves a post that is not linked to a cell group', () {
      expect(
        PostTitleAttendees.resolveNewCellGroupTitle(
          title: 'Sunday Service',
          defaultTitle: 'Sunday Service',
          linkedToCellGroup: false,
          shortenedNames: names,
          random: Random(1),
        ),
        'Sunday Service',
      );
    });

    test('leaves the default title when nobody attended', () {
      expect(
        PostTitleAttendees.resolveNewCellGroupTitle(
          title: "Diego's Cell group",
          defaultTitle: "Diego's Cell group",
          linkedToCellGroup: true,
          shortenedNames: const [],
        ),
        "Diego's Cell group",
      );
    });

    test('treats surrounding whitespace as the same default title', () {
      final title = PostTitleAttendees.resolveNewCellGroupTitle(
        title: "  Diego's Cell group  ",
        defaultTitle: "Diego's Cell group",
        linkedToCellGroup: true,
        shortenedNames: const ['Ann A.'],
        random: Random(1),
      );

      expect(title, "Diego's Cell group w/ Ann A.");
    });
  });

  group('PostTitleAttendees.appendToTitle', () {
    test('shuffles with the given random before fitting', () {
      const names = [
        'Ann A.',
        'Bob B.',
        'Cara C.',
        'Dan D.',
        'Eve E.',
        'Fay F.',
        'Gil G.',
        'Hal H.',
      ];
      final shuffled = List<String>.from(names)..shuffle(Random(4));
      final title = PostTitleAttendees.appendToTitle(
        title: "Diego's Cell group",
        shortenedNames: names,
        random: Random(4),
      )!;

      final listed = _listedNames(title);
      expect(title, startsWith("Diego's Cell group w/ "));
      expect(listed, shuffled.take(listed.length).toList());
      expect(title, endsWith(' +${names.length - listed.length}'));
      expect(title.length, lessThanOrEqualTo(PostTitleAttendees.maxLength));
    });

    test('a second pass keeps one attendance ending', () {
      const names = [
        'Ann A.',
        'Bob B.',
        'Cara C.',
        'Dan D.',
        'Eve E.',
        'Fay F.',
        'Gil G.',
        'Hal H.',
      ];
      final once = PostTitleAttendees.appendToTitle(
        title: "Diego's Cell group",
        shortenedNames: names,
        random: Random(1),
      )!;
      final twice = PostTitleAttendees.appendToTitle(
        title: once,
        shortenedNames: names,
        random: Random(2),
      )!;

      expect(twice, startsWith("Diego's Cell group w/ "));
      expect(' w/ '.allMatches(twice), hasLength(1));
    });

    test('does not mutate the caller list', () {
      final names = ['Ann A.', 'Bob B.', 'Cara C.', 'Dan D.'];
      final copy = List<String>.from(names);
      PostTitleAttendees.appendToTitle(
        title: 'Group',
        shortenedNames: names,
        random: Random(3),
      );
      expect(names, copy);
    });
  });
}

List<String> _listedNames(String title) {
  final marker = PostTitleAttendees.marker;
  final suffix = title.substring(title.lastIndexOf(marker) + marker.length);
  final namesPart = suffix.replaceFirst(RegExp(r' \+\d+$'), '');
  return namesPart.split(', ');
}
