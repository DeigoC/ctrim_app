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
}
