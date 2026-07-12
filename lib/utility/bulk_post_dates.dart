DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

/// Weekly post dates for bulk creation.
///
/// When [anchorDate] is set (e.g. the source post's event date), the first
/// generated date is the next [dayOfWeek] on or after one week later.
/// Otherwise dates start from the next [dayOfWeek] after [now] (default today).
List<DateTime> computeBulkPostDates({
  required int dayOfWeek,
  required int weeks,
  DateTime? anchorDate,
  DateTime? now,
}) {
  final DateTime base;
  if (anchorDate != null) {
    base = _dateOnly(anchorDate).add(const Duration(days: 7));
  } else {
    final reference = now ?? DateTime.now();
    base = _dateOnly(reference).add(const Duration(days: 1));
  }
  final daysUntil = (dayOfWeek - base.weekday + 7) % 7;
  final firstDate = base.add(Duration(days: daysUntil));
  return List.generate(weeks, (i) => firstDate.add(Duration(days: 7 * i)));
}
