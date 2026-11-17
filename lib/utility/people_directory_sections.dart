import 'package:flutter/foundation.dart';

import '../models/user.dart';

/// One A–Z (or #) section in the people directory.
class PeopleDirectorySection {
  const PeopleDirectorySection({
    required this.letter,
    required this.users,
  });

  final String letter;
  final List<User> users;
}

/// A run of people in surname order.
///
/// [surnameLabel] is set only when every person shares that surname and the
/// run has at least two people — a family-sized cluster the picker can select
/// together. A single surname, or a blank surname, stays in a plain run.
class PeopleDirectorySurnameBlock {
  const PeopleDirectorySurnameBlock({
    required this.users,
    this.surnameLabel,
  });

  final List<User> users;
  final String? surnameLabel;

  bool get canSelectTogether => surnameLabel != null;
}

/// Groups a surname-sorted people list into letter sections.
class PeopleDirectorySections {
  PeopleDirectorySections._();

  static final RegExp _alpha = RegExp(r'[A-Z]');

  /// First letter bucket for [user] (surname, then forename, else `#`).
  static String letterForUser(User user) {
    final surname = user.surname.trim();
    final source = surname.isNotEmpty ? surname : user.forname.trim();
    if (source.isEmpty) return '#';
    final letter = source[0].toUpperCase();
    return _alpha.hasMatch(letter) ? letter : '#';
  }

  /// Assumes [users] is already sorted by surname.
  static List<PeopleDirectorySection> bySurnameLetter(List<User> users) {
    if (users.isEmpty) return const [];

    final sections = <PeopleDirectorySection>[];
    var currentLetter = '';
    var bucket = <User>[];

    void flush() {
      if (bucket.isEmpty) return;
      sections
          .add(PeopleDirectorySection(letter: currentLetter, users: bucket));
      bucket = <User>[];
    }

    for (final user in users) {
      final letter = letterForUser(user);
      if (letter != currentLetter) {
        flush();
        currentLetter = letter;
      }
      bucket.add(user);
    }
    flush();
    return sections;
  }

  /// Surname key used to cluster a family. Blank surnames do not cluster.
  static String surnameKey(User user) => user.surname.trim().toLowerCase();

  /// Splits a surname-sorted list into family clusters and the people between them.
  ///
  /// Two or more neighbours with the same non-empty surname become one block
  /// with [PeopleDirectorySurnameBlock.surnameLabel]. Everyone else is merged
  /// into the surrounding plain block so a letter section stays one list until
  /// a family starts. Case differences (`Campbell` / `campbell`) share a block;
  /// the label is the first person's surname as stored.
  static List<PeopleDirectorySurnameBlock> bySurname(List<User> users) {
    if (users.isEmpty) return const [];

    final blocks = <PeopleDirectorySurnameBlock>[];
    final loose = <User>[];

    void flushLoose() {
      if (loose.isEmpty) return;
      blocks.add(PeopleDirectorySurnameBlock(users: List<User>.of(loose)));
      loose.clear();
    }

    var index = 0;
    while (index < users.length) {
      final key = surnameKey(users[index]);
      if (key.isEmpty) {
        loose.add(users[index]);
        index++;
        continue;
      }

      var end = index + 1;
      while (end < users.length && surnameKey(users[end]) == key) {
        end++;
      }
      final run = users.sublist(index, end);
      if (run.length >= 2) {
        flushLoose();
        blocks.add(
          PeopleDirectorySurnameBlock(
            users: List<User>.of(run),
            surnameLabel: run.first.surname.trim(),
          ),
        );
      } else {
        loose.add(run.first);
      }
      index = end;
    }
    flushLoose();
    return blocks;
  }

  /// One flat list for a single lazy sliver.
  ///
  /// A sliver per letter or surname builds its first row on the opening frame
  /// even when that section is below the fold. Headings are rows here so only
  /// the visible window is built. [peoplePerRow] is 1 on a phone and the wide
  /// grid's column count; a short last row is not stretched, and a row never
  /// crosses a letter or surname heading.
  static List<PeopleDirectoryScrollLine> scrollLines({
    required List<User> users,
    required bool useLetterSections,
    required bool groupSurnames,
    required int peoplePerRow,
  }) {
    if (users.isEmpty) return const [];

    final rowSize = peoplePerRow < 1 ? 1 : peoplePerRow;
    final sections = useLetterSections
        ? bySurnameLetter(users)
        : [PeopleDirectorySection(letter: '', users: users)];
    final lines = <PeopleDirectoryScrollLine>[];

    void addPeople(List<User> people) {
      for (var start = 0; start < people.length; start += rowSize) {
        final end =
            start + rowSize > people.length ? people.length : start + rowSize;
        lines.add(
          PeopleDirectoryScrollLine.people(people.sublist(start, end)),
        );
      }
    }

    for (final section in sections) {
      if (useLetterSections && section.letter.isNotEmpty) {
        lines.add(PeopleDirectoryScrollLine.letter(section.letter));
      }
      final blocks = groupSurnames
          ? bySurname(section.users)
          : [PeopleDirectorySurnameBlock(users: section.users)];
      for (final block in blocks) {
        if (block.canSelectTogether) {
          lines.add(
            PeopleDirectoryScrollLine.surname(
              surnameLabel: block.surnameLabel!,
              users: block.users,
            ),
          );
        }
        addPeople(block.users);
      }
    }
    return lines;
  }

  static int? indexForKey(List<PeopleDirectoryScrollLine> lines, Key key) {
    if (key is! ValueKey<String>) return null;
    final value = key.value;
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].storageKey == value) return i;
    }
    return null;
  }
}

/// Column count for the wide people grid (`maxCrossAxisExtent` 420).
///
/// Matches Flutter's max-cross-axis-extent grid so a hand-built row has the
/// same card width as the grid it replaced.
abstract final class PeopleDirectoryGrid {
  static const double maxCrossAxisExtent = 420;
  static const double crossAxisSpacing = 12;
  static const double mainAxisSpacing = 8;

  static int crossAxisCount(double crossAxisExtent) {
    if (crossAxisExtent <= 0) return 1;
    final count =
        (crossAxisExtent / (maxCrossAxisExtent + crossAxisSpacing)).ceil();
    return count < 1 ? 1 : count;
  }

  static double childCrossAxisExtent(double crossAxisExtent) {
    final count = crossAxisCount(crossAxisExtent);
    final usable = crossAxisExtent - crossAxisSpacing * (count - 1);
    if (usable <= 0) return 0;
    return usable / count;
  }
}

/// One row in the people directory's single lazy list.
class PeopleDirectoryScrollLine {
  const PeopleDirectoryScrollLine.letter(this.letter)
      : users = const [],
        surnameLabel = null;

  const PeopleDirectoryScrollLine.surname({
    required this.surnameLabel,
    required this.users,
  }) : letter = null;

  const PeopleDirectoryScrollLine.people(this.users)
      : letter = null,
        surnameLabel = null;

  final String? letter;
  final String? surnameLabel;

  /// Family members for a surname heading, or the people packed into this row.
  final List<User> users;

  bool get isLetter => letter != null;

  bool get isSurname => surnameLabel != null;

  bool get isPeople => letter == null && surnameLabel == null;

  String get storageKey {
    if (letter != null) return 'letter:$letter';
    if (surnameLabel != null) {
      return 'surname:${surnameLabel!.toLowerCase()}:${users.first.id}';
    }
    return 'people:${users.map((user) => user.id).join(',')}';
  }
}
