import 'package:ctrim_app/models/event/event_head.dart';
import 'package:ctrim_app/utility/activity_time_series.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ActivityTimeSeries', () {
    test('empty input yields zero-filled weeks', () {
      final start = DateTime(2026, 6, 1);
      final end = DateTime(2026, 6, 15);
      final points = ActivityTimeSeries.bucketWeeklyCount(
        eventDates: const [],
        startInclusive: start,
        endExclusive: end,
      );

      expect(points.length, 2);
      expect(points.every((p) => p.value == 0), isTrue);
      expect(points.first.weekStart, DateTime(2026, 6, 1));
    });

    test('bucketWeeklyCount groups by ISO week and zero-fills gaps', () {
      final points = ActivityTimeSeries.bucketWeeklyCount(
        eventDates: [
          DateTime(2026, 6, 3),
          DateTime(2026, 6, 4),
          DateTime(2026, 6, 17),
        ],
        startInclusive: DateTime(2026, 6, 1),
        endExclusive: DateTime(2026, 6, 22),
      );

      expect(points.length, 3);
      expect(points[0].value, 2);
      expect(points[1].value, 0);
      expect(points[2].value, 1);
    });

    test('bucketWeeklySum sums amounts per week', () {
      final points = ActivityTimeSeries.bucketWeeklySum(
        entries: [
          (date: DateTime(2026, 6, 3), amount: 5),
          (date: DateTime(2026, 6, 4), amount: 3),
          (date: DateTime(2026, 6, 17), amount: 10),
        ],
        startInclusive: DateTime(2026, 6, 1),
        endExclusive: DateTime(2026, 6, 22),
      );

      expect(points[0].value, 8);
      expect(points[2].value, 10);
    });

    test('fromPosts excludes out-of-range dates', () {
      final post = EventHead(
        id: 'p1',
        title: 'Post',
        location: 'Belfast',
      );
      post.setEventDate(DateTime(2026, 8, 10));
      post.setAttendeeCount(12);

      final outOfRange = EventHead(id: 'old', title: 'Old');
      outOfRange.setEventDate(DateTime(2026, 5, 1));
      outOfRange.setAttendeeCount(99);

      final countPoints = ActivityTimeSeries.fromPosts(
        posts: [post, outOfRange],
        metric: ActivityTimeSeriesMetric.count,
        startInclusive: DateTime(2026, 8, 1),
        endExclusive: DateTime(2026, 8, 31),
      );
      expect(ActivityTimeSeries.hasNonZeroValues(countPoints), isTrue);
      expect(countPoints.any((p) => p.value == 1), isTrue);

      final attendancePoints = ActivityTimeSeries.fromPosts(
        posts: [post, outOfRange],
        metric: ActivityTimeSeriesMetric.attendance,
        startInclusive: DateTime(2026, 8, 1),
        endExclusive: DateTime(2026, 8, 31),
      );
      expect(attendancePoints.any((p) => p.value == 12), isTrue);
    });

    test('fromCellGroupMeetings ignores heads without cell group linkage', () {
      final meeting = EventHead(
        id: 'm1',
        title: 'CG',
        cellGroupIDs: ['cg1'],
      );
      meeting.setEventDate(DateTime(2026, 8, 10));

      final plain = EventHead(id: 'e1', title: 'Event');
      plain.setEventDate(DateTime(2026, 8, 11));

      final points = ActivityTimeSeries.fromCellGroupMeetings(
        meetings: [meeting, plain],
        metric: ActivityTimeSeriesMetric.count,
        startInclusive: DateTime(2026, 8, 1),
        endExclusive: DateTime(2026, 8, 31),
      );

      expect(ActivityTimeSeries.hasNonZeroValues(points), isTrue);
      final total = points.fold<double>(0, (sum, p) => sum + p.value);
      expect(total, 1);
    });

    test('hasNonZeroValues is false when all buckets are zero', () {
      final points = ActivityTimeSeries.bucketWeeklyCount(
        eventDates: const [],
        startInclusive: DateTime(2026, 6, 1),
        endExclusive: DateTime(2026, 6, 15),
      );
      expect(ActivityTimeSeries.hasNonZeroValues(points), isFalse);
    });
  });
}
