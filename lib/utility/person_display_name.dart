import '../models/user.dart';

/// Guest-facing labels for a person, including stored names with no profile.
class PersonDisplayName {
  PersonDisplayName._();

  static final RegExp _alreadyInitial = RegExp(r'^[A-Za-z]{1,4}\.$');

  /// Lead speaker line on a bulletin card.
  ///
  /// Prefers the live profile. When that profile is missing, guests get an
  /// abbreviated form of the stored full name.
  static String leadSpeakerLabel({
    required String? storedName,
    required User? user,
    required bool guest,
  }) {
    if (user != null) return user.nameForViewer(guest: guest);
    final stored = storedName?.trim() ?? '';
    if (stored.isEmpty) return 'Lead speaker';
    if (!guest) return stored;
    return abbreviateStoredPersonalName(stored);
  }

  /// `Adam Barr` becomes `Adam B.`. A name that is already `Adam B.` stays put.
  static String abbreviateStoredPersonalName(String stored) {
    final parts = stored
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.length < 2) return stored.trim();
    final last = parts.last;
    if (_alreadyInitial.hasMatch(last)) return parts.join(' ');
    parts[parts.length - 1] = _surnameInitial(last);
    return parts.join(' ');
  }

  static String _surnameInitial(String surname) {
    final letters = surname
        .split('-')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase())
        .join();
    if (letters.isEmpty) return surname;
    return '$letters.';
  }
}
