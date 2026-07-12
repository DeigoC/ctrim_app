import 'package:ctrim_app/utility/bulk_post_dates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeBulkPostDates', () {
    test('uses week after anchor date when provided', () {
      // Source post: Sunday 19 Jul 2026; template day Sunday (7).
      final anchor = DateTime(2026, 7, 19);
      final dates = computeBulkPostDates(
        dayOfWeek: 7,
        weeks: 3,
        anchorDate: anchor,
      );

      expect(dates, [
        DateTime(2026, 7, 26),
        DateTime(2026, 8, 2),
        DateTime(2026, 8, 9),
      ]);
    });

    test('aligns to selected weekday after anchor week', () {
      // Source post: Sunday 19 Jul 2026; bulk on Mondays (1).
      final anchor = DateTime(2026, 7, 19);
      final dates = computeBulkPostDates(
        dayOfWeek: 1,
        weeks: 2,
        anchorDate: anchor,
      );

      expect(dates, [
        DateTime(2026, 7, 27),
        DateTime(2026, 8, 3),
      ]);
    });

    test('falls back to upcoming dates from now when no anchor', () {
      final now = DateTime(2026, 7, 12); // Sunday
      final dates = computeBulkPostDates(
        dayOfWeek: 1,
        weeks: 2,
        now: now,
      );

      expect(dates, [
        DateTime(2026, 7, 13),
        DateTime(2026, 7, 20),
      ]);
    });
  });
}
