import '../models/event/event_attendance.dart';
import '../models/user.dart';
import 'catalog/user_tag_helpers.dart';

/// Surname order for a post's expected checklist and attended list.
///
/// Stored ids stay in save order. These helpers only change what the People
/// tab shows, so an existing post does not need to be rewritten.
class AttendanceNameOrder {
  AttendanceNameOrder._();

  static List<String> userIdsBySurname(
    Iterable<String> userIds,
    User? Function(String userId) userById,
  ) {
    final sorted = List<String>.from(userIds);
    sorted.sort((a, b) => _compareUserIds(a, b, userById));
    return sorted;
  }

  static List<AttendeeEntry> attendeesBySurname(
    Iterable<AttendeeEntry> attendees,
    User? Function(String userId) userById,
  ) {
    final sorted = List<AttendeeEntry>.from(attendees);
    sorted.sort((a, b) => _compareAttendees(a, b, userById));
    return sorted;
  }

  static int _compareUserIds(
    String a,
    String b,
    User? Function(String userId) userById,
  ) {
    final userA = userById(a);
    final userB = userById(b);
    if (userA != null && userB != null) {
      return UserTagHelpers.compareUsersBySurname(userA, userB);
    }
    final byName = _labelForMissingUser(a, userA)
        .toLowerCase()
        .compareTo(_labelForMissingUser(b, userB).toLowerCase());
    if (byName != 0) return byName;
    return a.toLowerCase().compareTo(b.toLowerCase());
  }

  static int _compareAttendees(
    AttendeeEntry a,
    AttendeeEntry b,
    User? Function(String userId) userById,
  ) {
    final userA = _userFor(a, userById);
    final userB = _userFor(b, userById);
    if (userA != null && userB != null) {
      return UserTagHelpers.compareUsersBySurname(userA, userB);
    }
    final bySurname = _surnameKey(a, userA)
        .toLowerCase()
        .compareTo(_surnameKey(b, userB).toLowerCase());
    if (bySurname != 0) return bySurname;
    final byName =
        a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
    if (byName != 0) return byName;
    return a.id.toLowerCase().compareTo(b.id.toLowerCase());
  }

  static User? _userFor(
    AttendeeEntry entry,
    User? Function(String userId) userById,
  ) {
    final userId = entry.userId;
    if (!entry.isUser || userId == null || userId.isEmpty) return null;
    return userById(userId);
  }

  static String _labelForMissingUser(String userId, User? user) {
    if (user == null) return userId;
    if (user.surname.trim().isNotEmpty) return user.surname;
    return user.forname;
  }

  static String _surnameKey(AttendeeEntry entry, User? user) {
    if (user != null && user.surname.trim().isNotEmpty) return user.surname;
    return _lastToken(entry.displayName);
  }

  static String _lastToken(String displayName) {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return displayName;
    return parts.last;
  }
}
