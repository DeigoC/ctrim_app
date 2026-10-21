import 'package:ctrim_app/utility/bulk_post_dates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeBulkPostDates', () {
    test('starts the week after a source post on the same weekday', () {
      // Source post: Sunday 19 Jul 2026; template day Sunday (7).
      final anchor = DateTime(2026, 7, 19);
      final dates = computeBulkPostDates(
        daysOfWeek: [7],
        weeks: 3,
        anchorDate: anchor,
      );

      expect(dates, [
        DateTime(2026, 7, 26),
        DateTime(2026, 8, 2),
        DateTime(2026, 8, 9),
      ]);
    });

    test('starts the day after a source post, keeping that week', () {
      // Source post: Tuesday 21 Jul 2026; bulk on Fridays (5).
      final anchor = DateTime(2026, 7, 21);
      final dates = computeBulkPostDates(
        daysOfWeek: [5],
        weeks: 2,
        anchorDate: anchor,
      );

      expect(dates, [
        DateTime(2026, 7, 24),
        DateTime(2026, 7, 31),
      ]);
    });

    test('includes the other selected days in the source post week', () {
      // Source post: Tuesday 21 Jul 2026; bulk on Tuesday + Thursday.
      final anchor = DateTime(2026, 7, 21);
      final dates = computeBulkPostDates(
        daysOfWeek: [2, 4],
        weeks: 2,
        anchorDate: anchor,
      );

      expect(dates, [
        DateTime(2026, 7, 23),
        DateTime(2026, 7, 28),
        DateTime(2026, 7, 30),
        DateTime(2026, 8, 4),
      ]);
    });

    test('makes weeks × days dates in date order whatever the day order', () {
      final now = DateTime(2026, 7, 12); // Sunday
      final dates = computeBulkPostDates(
        daysOfWeek: [5, 1, 3],
        weeks: 2,
        now: now,
      );

      expect(dates, [
        DateTime(2026, 7, 13),
        DateTime(2026, 7, 15),
        DateTime(2026, 7, 17),
        DateTime(2026, 7, 20),
        DateTime(2026, 7, 22),
        DateTime(2026, 7, 24),
      ]);
    });

    test('falls back to upcoming dates from now when no anchor', () {
      final now = DateTime(2026, 7, 12); // Sunday
      final dates = computeBulkPostDates(
        daysOfWeek: [1],
        weeks: 2,
        now: now,
      );

      expect(dates, [
        DateTime(2026, 7, 13),
        DateTime(2026, 7, 20),
      ]);
    });

    test('returns nothing without days or weeks', () {
      expect(computeBulkPostDates(daysOfWeek: const [], weeks: 4), isEmpty);
      expect(computeBulkPostDates(daysOfWeek: [1], weeks: 0), isEmpty);
    });
  });

  group('maxBulkWeeksFor', () {
    test('keeps every run within the post limit', () {
      for (var days = 1; days <= 7; days++) {
        final weeks = maxBulkWeeksFor(days);
        expect(weeks * days, lessThanOrEqualTo(maxBulkPosts));
        expect(weeks, greaterThanOrEqualTo(1));
        expect(weeks, lessThanOrEqualTo(maxBulkWeeks));
      }
    });

    test('allows the full slider for one or two days', () {
      expect(maxBulkWeeksFor(1), maxBulkWeeks);
      expect(maxBulkWeeksFor(2), maxBulkWeeks);
      expect(maxBulkWeeksFor(3), 10);
      expect(maxBulkWeeksFor(7), 4);
    });
  });

  group('nextDateForDaysOfWeek', () {
    test('returns today when it already matches', () {
      final sunday = DateTime(2026, 7, 12);
      expect(
        nextDateForDaysOfWeek(daysOfWeek: [3, 7], now: sunday),
        DateTime(2026, 7, 12),
      );
    });

    test('picks the soonest of several weekdays', () {
      final sunday = DateTime(2026, 7, 12);
      expect(
        nextDateForDaysOfWeek(daysOfWeek: [5, 2], now: sunday),
        DateTime(2026, 7, 14),
      );
    });

    test('returns null without days', () {
      expect(nextDateForDaysOfWeek(daysOfWeek: const []), isNull);
    });
  });

  group('everyDaysOfWeekLabel', () {
    test('joins names in weekday order', () {
      expect(everyDaysOfWeekLabel([2]), 'Every Tuesday');
      expect(everyDaysOfWeekLabel([4, 2]), 'Every Tuesday & Thursday');
      expect(
          everyDaysOfWeekLabel([5, 1, 3]), 'Every Monday, Wednesday & Friday');
    });

    test('says every day for all seven and nothing for none', () {
      expect(everyDaysOfWeekLabel([1, 2, 3, 4, 5, 6, 7]), 'Every day');
      expect(everyDaysOfWeekLabel(const []), '');
    });
  });
}
