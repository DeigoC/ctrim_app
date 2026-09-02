import '../models/event/event_head.dart';

/// Weekly bucket for activity line charts.
class TimeSeriesPoint {
  const TimeSeriesPoint({
    required this.weekStart,
    required this.value,
  });

  /// Local Monday 00:00 for the bucket.
  final DateTime weekStart;

  final double value;
}

/// Count (posts/meetings) vs sum of attendance per week.
enum ActivityTimeSeriesMetric {
  count,
  attendance,
}

/// Buckets [EventHead.eventDate] into ISO weeks (Monday start) with zero-fill.
class ActivityTimeSeries {
  const ActivityTimeSeries._();

  static DateTime dayStart(final DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Monday 00:00 local for the week containing [date].
  static DateTime weekStartMonday(final DateTime date) {
    final local = dayStart(date);
    return local.subtract(Duration(days: local.weekday - DateTime.monday));
  }

  static bool hasNonZeroValues(final List<TimeSeriesPoint> points) =>
      points.any((final p) => p.value > 0);

  /// Weekly post counts or attendee sums for church-hub location posts.
  static List<TimeSeriesPoint> fromPosts({
    required List<EventHead> posts,
    required ActivityTimeSeriesMetric metric,
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) {
    if (metric == ActivityTimeSeriesMetric.count) {
      final dates = <DateTime>[];
      for (final head in posts) {
        final date = head.eventDate;
        if (date == null) continue;
        if (date.isBefore(startInclusive) || !date.isBefore(endExclusive)) {
          continue;
        }
        dates.add(date);
      }
      return bucketWeeklyCount(
        eventDates: dates,
        startInclusive: startInclusive,
        endExclusive: endExclusive,
      );
    }

    final entries = <({DateTime date, int amount})>[];
    for (final head in posts) {
      final date = head.eventDate;
      if (date == null) continue;
      if (date.isBefore(startInclusive) || !date.isBefore(endExclusive)) {
        continue;
      }
      entries.add((date: date, amount: head.attendeeCount));
    }
    return bucketWeeklySum(
      entries: entries,
      startInclusive: startInclusive,
      endExclusive: endExclusive,
    );
  }

  /// Weekly meeting counts or attendee sums for CG-linked bulletin heads.
  ///
  /// When [cellGroupId] is set, only meetings linked to that group count.
  static List<TimeSeriesPoint> fromCellGroupMeetings({
    required List<EventHead> meetings,
    required ActivityTimeSeriesMetric metric,
    required DateTime startInclusive,
    required DateTime endExclusive,
    String? cellGroupId,
  }) {
    final groupId = cellGroupId?.trim();
    final linked = <EventHead>[];
    for (final head in meetings) {
      if (head.cellGroupIDs.isEmpty) continue;
      if (groupId != null &&
          groupId.isNotEmpty &&
          !head.cellGroupIDs.contains(groupId)) {
        continue;
      }
      final date = head.eventDate;
      if (date == null) continue;
      if (date.isBefore(startInclusive) || !date.isBefore(endExclusive)) {
        continue;
      }
      linked.add(head);
    }
    return fromPosts(
      posts: linked,
      metric: metric,
      startInclusive: startInclusive,
      endExclusive: endExclusive,
    );
  }

  static List<TimeSeriesPoint> bucketWeeklyCount({
    required List<DateTime> eventDates,
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) {
    final buckets = <DateTime, double>{};
    for (final date in eventDates) {
      if (date.isBefore(startInclusive) || !date.isBefore(endExclusive)) {
        continue;
      }
      final key = weekStartMonday(date);
      buckets[key] = (buckets[key] ?? 0) + 1;
    }
    return _zeroFilledSeries(
      startInclusive: startInclusive,
      endExclusive: endExclusive,
      buckets: buckets,
    );
  }

  static List<TimeSeriesPoint> bucketWeeklySum({
    required List<({DateTime date, int amount})> entries,
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) {
    final buckets = <DateTime, double>{};
    for (final entry in entries) {
      final date = entry.date;
      if (date.isBefore(startInclusive) || !date.isBefore(endExclusive)) {
        continue;
      }
      final key = weekStartMonday(date);
      buckets[key] = (buckets[key] ?? 0) + entry.amount;
    }
    return _zeroFilledSeries(
      startInclusive: startInclusive,
      endExclusive: endExclusive,
      buckets: buckets,
    );
  }

  static List<TimeSeriesPoint> _zeroFilledSeries({
    required DateTime startInclusive,
    required DateTime endExclusive,
    required Map<DateTime, double> buckets,
  }) {
    if (!endExclusive.isAfter(startInclusive)) {
      return const <TimeSeriesPoint>[];
    }

    final List<TimeSeriesPoint> result = <TimeSeriesPoint>[];
    var week = weekStartMonday(startInclusive);
    final lastDay = endExclusive.subtract(const Duration(days: 1));
    final lastWeek = weekStartMonday(lastDay);

    while (!week.isAfter(lastWeek)) {
      result.add(TimeSeriesPoint(weekStart: week, value: buckets[week] ?? 0));
      week = week.add(const Duration(days: 7));
    }
    return result;
  }
}
