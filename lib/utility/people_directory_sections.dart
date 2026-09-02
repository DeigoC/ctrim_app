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
      sections.add(PeopleDirectorySection(letter: currentLetter, users: bucket));
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
}
