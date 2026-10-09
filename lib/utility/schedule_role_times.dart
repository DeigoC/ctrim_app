/// Whether a schedule role's start and finish can be saved, and how to read them.
class ScheduleRoleTimes {
  /// A running-order line needs both times. A whole-event role may omit the
  /// finish, or omit both. An end with no start cannot be saved.
  static bool areSavable({
    required DateTime? start,
    required DateTime? end,
    required bool standing,
  }) {
    if (end != null && start == null) return false;
    if (start != null && end != null) return true;
    return standing;
  }

  /// Clock-only comparison. A null matches only another null.
  static bool sameClock(final DateTime? a, final DateTime? b) {
    if (a == null || b == null) return a == null && b == null;
    return a.hour == b.hour && a.minute == b.minute;
  }

  /// Text for a role's clock times. Null when a running-order role has none.
  ///
  /// [prefixWholeEvent] puts the whole-event label in front of a clock time.
  /// The All event band leaves it off, because that section already says so.
  static String? label({
    required DateTime? start,
    required DateTime? end,
    required bool standing,
    required String wholeEvent,
    required String Function(DateTime time) formatTime,
    required String Function(String formattedTime) startsAt,
    String Function(DateTime start, DateTime end)? range,
    bool prefixWholeEvent = false,
  }) {
    if (start != null && end != null) {
      final text = range?.call(start, end) ??
          '${formatTime(start)} - ${formatTime(end)}';
      if (prefixWholeEvent && standing) return '$wholeEvent · $text';
      return text;
    }
    if (!standing) return null;
    if (start != null) {
      final text = startsAt(formatTime(start));
      if (prefixWholeEvent) return '$wholeEvent · $text';
      return text;
    }
    return wholeEvent;
  }
}
