/// Europe/London wall clock without a timezone package.
///
/// EU BST: last Sunday of March 01:00 UTC inclusive, through last Sunday of
/// October 01:00 UTC exclusive. Keep this in step with
/// `functions/notification_schedule.py`.
class LondonTime {
  LondonTime._();

  static const List<String> weekdayAbbrev = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const List<String> monthAbbrev = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// Day of month of the last Sunday in [month] (1–12).
  static int lastSundayOfMonth(int year, int month) {
    final last = DateTime.utc(year, month + 1, 0);
    final daysBack = last.weekday % 7;
    return last.day - daysBack;
  }

  static bool isBst(DateTime instant) {
    final utc = instant.toUtc();
    final start = DateTime.utc(utc.year, 3, lastSundayOfMonth(utc.year, 3), 1);
    final end = DateTime.utc(utc.year, 10, lastSundayOfMonth(utc.year, 10), 1);
    return !utc.isBefore(start) && utc.isBefore(end);
  }

  /// London calendar fields for [instant].
  static LondonWall wall(DateTime instant) {
    final utc = instant.toUtc();
    final shifted = isBst(utc) ? utc.add(const Duration(hours: 1)) : utc;
    return LondonWall(
      year: shifted.year,
      month: shifted.month,
      day: shifted.day,
      hour: shifted.hour,
      minute: shifted.minute,
      weekday: shifted.weekday,
    );
  }

  /// UTC instant for a London wall time. Null when that clock time does not
  /// exist (the spring-forward gap).
  static DateTime? wallToUtc({
    required int year,
    required int month,
    required int day,
    required int hour,
    required int minute,
  }) {
    for (final offset in [0, 1]) {
      final utc = DateTime.utc(year, month, day, hour, minute)
          .subtract(Duration(hours: offset));
      final actual = isBst(utc) ? 1 : 0;
      if (actual == offset) return utc;
    }
    return null;
  }

  /// `Sat, Oct 3 · 18:00` in Europe/London.
  static String format(DateTime instant) {
    final local = wall(instant);
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${weekdayAbbrev[local.weekday - 1]}, '
        '${monthAbbrev[local.month - 1]} ${local.day} · $hour:$minute';
  }
}

class LondonWall {
  const LondonWall({
    required this.year,
    required this.month,
    required this.day,
    required this.hour,
    required this.minute,
    required this.weekday,
  });

  final int year;
  final int month;
  final int day;
  final int hour;
  final int minute;

  /// Dart weekday: Monday is 1, Sunday is 7.
  final int weekday;
}
