DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

/// Calendar days. A [Duration] of one day is 24 hours, so on the Sunday the
/// clocks go back that step is still the same date.
DateTime _addCalendarDays(DateTime date, int days) =>
    DateTime(date.year, date.month, date.day + days);

/// Most posts one bulk run may create.
const int maxBulkPosts = 30;

/// Longest bulk run, whatever the number of days.
const int maxBulkWeeks = 12;

const List<String> _dayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// Soonest calendar date on any of [daysOfWeek] (1 = Mon … 7 = Sun),
/// including [now] when that weekday matches. Null when no day is given.
DateTime? nextDateForDaysOfWeek({
  required Iterable<int> daysOfWeek,
  DateTime? now,
}) {
  final reference = _dateOnly(now ?? DateTime.now());
  DateTime? soonest;
  for (final day in daysOfWeek) {
    final daysUntil = (day - reference.weekday + 7) % 7;
    final candidate = _addCalendarDays(reference, daysUntil);
    if (soonest == null || candidate.isBefore(soonest)) soonest = candidate;
  }
  return soonest;
}

/// Post dates for bulk creation: every one of [daysOfWeek] in each of the next
/// [weeks] weeks, in date order (`weeks × days` dates).
///
/// The run starts the day after [anchorDate] (the source post's event date)
/// when set, otherwise the day after [now] (default today).
List<DateTime> computeBulkPostDates({
  required Iterable<int> daysOfWeek,
  required int weeks,
  DateTime? anchorDate,
  DateTime? now,
}) {
  final days = daysOfWeek.toSet();
  if (days.isEmpty || weeks <= 0) return const [];
  final start =
      _addCalendarDays(_dateOnly(anchorDate ?? now ?? DateTime.now()), 1);
  return [
    for (var offset = 0; offset < weeks * 7; offset++)
      if (days.contains(_addCalendarDays(start, offset).weekday))
        _addCalendarDays(start, offset),
  ];
}

/// Most weeks a run can cover with [dayCount] days and stay within
/// [maxBulkPosts].
int maxBulkWeeksFor(final int dayCount) {
  if (dayCount <= 0) return maxBulkWeeks;
  final byPosts = maxBulkPosts ~/ dayCount;
  return byPosts < maxBulkWeeks ? byPosts : maxBulkWeeks;
}

/// "Every Tuesday", "Every Tuesday & Thursday", "Every Monday, Wednesday &
/// Friday", or "Every day". Empty when no valid day is given.
String everyDaysOfWeekLabel(final Iterable<int> daysOfWeek) {
  final days = daysOfWeek.where((d) => d >= 1 && d <= 7).toSet().toList()
    ..sort();
  if (days.isEmpty) return '';
  if (days.length == 7) return 'Every day';
  final names = [for (final day in days) _dayNames[day - 1]];
  if (names.length == 1) return 'Every ${names.single}';
  return 'Every ${names.sublist(0, names.length - 1).join(', ')} '
      '& ${names.last}';
}
