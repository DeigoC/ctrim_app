import 'dart:math';

import '../models/event/event_attendance.dart';
import '../models/user.dart';

/// Appends shuffled shortened attendee names to an existing post title.
///
/// The stem stays as written. A previous generated ` w/ …` ending is replaced.
/// Names use [User.shortenedFullName] (for example `John D.`), never the full
/// surname. The result stays within [maxLength]. People who do not fit are
/// counted as ` +N`.
class PostTitleAttendees {
  PostTitleAttendees._();

  static const int maxLength = 64;
  static const String marker = ' w/ ';

  static final RegExp _plusSuffix = RegExp(r' \+(\d+)$');
  static final RegExp _initialName = RegExp(r'^.+ [A-Za-z]+\.$');

  /// Shortened labels in attendee-list order. Blank and `?` names are omitted.
  static List<String> shortenedNames(
    Iterable<AttendeeEntry> attendees,
    User? Function(String userId) userById,
  ) {
    final names = <String>[];
    for (final entry in attendees) {
      final token = _token(_nameFor(entry, userById));
      if (token != null) names.add(token);
    }
    return names;
  }

  /// `Jane Doe` → `Jane D.`. A single word is kept. Hyphenated surnames keep
  /// each part's initial (`Ann Smith-Jones` → `Ann SJ.`).
  static String shortenedFromDisplayName(String fullName) {
    final trimmed =
        fullName.replaceAll(',', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (trimmed.isEmpty) return '';
    final parts = trimmed.split(' ');
    if (parts.length == 1) return parts.single;
    final surname = parts.last;
    final forename = parts.sublist(0, parts.length - 1).join(' ');
    final initials = surname
        .split('-')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0])
        .join();
    if (forename.isEmpty && initials.isEmpty) return '';
    if (initials.isEmpty) return forename;
    return '$forename $initials.';
  }

  /// Title written when a new cell-group post is saved.
  ///
  /// When [title] still matches [defaultTitle] and the post is linked to a
  /// cell group, appends [shortenedNames]. A custom title, a post with no
  /// cell group, or an empty name list is returned unchanged. Pass only the
  /// people who will be stored as attended.
  static String resolveNewCellGroupTitle({
    required String title,
    required String defaultTitle,
    required bool linkedToCellGroup,
    required List<String> shortenedNames,
    Random? random,
  }) {
    final typed = title.trim();
    if (!linkedToCellGroup || typed != defaultTitle.trim()) return typed;
    return appendToTitle(
          title: typed,
          shortenedNames: shortenedNames,
          random: random,
        ) ??
        typed;
  }

  /// Shuffles [shortenedNames], then fits a prefix into the title.
  static String? appendToTitle({
    required String title,
    required List<String> shortenedNames,
    Random? random,
  }) {
    final names = _tokens(shortenedNames);
    if (names.isEmpty) return null;
    names.shuffle(random ?? Random());
    return appendOrderedNames(title: title, orderedNames: names);
  }

  /// Fits [orderedNames] in the given order. Does not shuffle.
  static String? appendOrderedNames({
    required String title,
    required List<String> orderedNames,
  }) {
    final names = _tokens(orderedNames);
    if (names.isEmpty) return null;

    final stem = _stem(title, names.toSet());
    if (stem.isEmpty) return null;
    final prefix = '$stem$marker';
    if (prefix.length > maxLength) return null;

    var fitted = 0;
    for (var count = 1; count <= names.length; count++) {
      final omitted = names.length - count;
      if (_composedLength(prefix, names.take(count), omitted) <= maxLength) {
        fitted = count;
      } else {
        break;
      }
    }
    if (fitted == 0) return null;

    final omitted = names.length - fitted;
    final body = names.take(fitted).join(', ');
    final extra = omitted > 0 ? ' +$omitted' : '';
    return '$prefix$body$extra';
  }

  static String _nameFor(
    AttendeeEntry entry,
    User? Function(String userId) userById,
  ) {
    final userId = entry.userId;
    if (entry.isUser && userId != null && userId.isNotEmpty) {
      final user = userById(userId);
      if (user != null) return user.shortenedFullName;
    }
    return shortenedFromDisplayName(entry.displayName);
  }

  static List<String> _tokens(Iterable<String> rawNames) {
    final names = <String>[];
    for (final raw in rawNames) {
      final token = _token(raw);
      if (token != null) names.add(token);
    }
    return names;
  }

  static String? _token(String raw) {
    final cleaned =
        raw.replaceAll(',', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.isEmpty || cleaned == '?') return null;
    return cleaned;
  }

  static String _stem(String title, Set<String> names) {
    final trimmed = title.trim();
    final index = trimmed.lastIndexOf(marker);
    if (index < 0) return trimmed;
    final suffix = trimmed.substring(index + marker.length);
    if (!_isAttendanceSuffix(suffix, names)) return trimmed;
    return trimmed.substring(0, index).trimRight();
  }

  static bool _isAttendanceSuffix(String suffix, Set<String> names) {
    var namesPart = suffix;
    final plus = _plusSuffix.firstMatch(suffix);
    if (plus != null) {
      final count = int.tryParse(plus.group(1)!);
      if (count == null || count < 1) return false;
      namesPart = suffix.substring(0, plus.start);
    }
    if (namesPart.isEmpty) return false;
    final tokens = namesPart.split(', ');
    if (tokens.isEmpty || tokens.any((token) => token.isEmpty)) return false;
    return tokens.every(
      (token) => names.contains(token) || _initialName.hasMatch(token),
    );
  }

  static int _composedLength(
    String prefix,
    Iterable<String> chosen,
    int omitted,
  ) {
    final body = chosen.join(', ');
    final extra = omitted > 0 ? ' +$omitted' : '';
    return prefix.length + body.length + extra.length;
  }
}
