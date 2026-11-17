import 'package:ctrim_app/utility/schedule_role_times.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final start = DateTime(2026, 6, 14, 9, 0);
  final end = DateTime(2026, 6, 14, 10, 30);

  String format(DateTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  group('ScheduleRoleTimes.areSavable', () {
    test('a running-order line needs both times', () {
      expect(
        ScheduleRoleTimes.areSavable(start: start, end: end, standing: false),
        isTrue,
      );
      expect(
        ScheduleRoleTimes.areSavable(start: start, end: null, standing: false),
        isFalse,
      );
      expect(
        ScheduleRoleTimes.areSavable(start: null, end: null, standing: false),
        isFalse,
      );
    });

    test('a whole-event role may omit the finish, or both times', () {
      expect(
        ScheduleRoleTimes.areSavable(start: null, end: null, standing: true),
        isTrue,
      );
      expect(
        ScheduleRoleTimes.areSavable(start: start, end: null, standing: true),
        isTrue,
      );
      expect(
        ScheduleRoleTimes.areSavable(start: start, end: end, standing: true),
        isTrue,
      );
    });

    test('an end with no start is not savable', () {
      expect(
        ScheduleRoleTimes.areSavable(start: null, end: end, standing: true),
        isFalse,
      );
      expect(
        ScheduleRoleTimes.areSavable(start: null, end: end, standing: false),
        isFalse,
      );
    });
  });

  group('ScheduleRoleTimes.sameClock', () {
    test('matches hour and minute, including both empty', () {
      expect(ScheduleRoleTimes.sameClock(null, null), isTrue);
      expect(ScheduleRoleTimes.sameClock(start, null), isFalse);
      expect(
        ScheduleRoleTimes.sameClock(start, DateTime(2026, 6, 15, 9, 0)),
        isTrue,
      );
      expect(ScheduleRoleTimes.sameClock(start, end), isFalse);
    });
  });

  group('ScheduleRoleTimes.label', () {
    String? read({
      required DateTime? start,
      required DateTime? end,
      required bool standing,
      bool prefixWholeEvent = false,
    }) {
      return ScheduleRoleTimes.label(
        start: start,
        end: end,
        standing: standing,
        wholeEvent: 'Whole event',
        formatTime: format,
        startsAt: (time) => 'From $time',
        prefixWholeEvent: prefixWholeEvent,
      );
    }

    test('a start-only whole-event role reads as from that time', () {
      expect(
        read(start: start, end: null, standing: true),
        'From 09:00',
      );
      expect(
        read(start: start, end: null, standing: true, prefixWholeEvent: true),
        'Whole event · From 09:00',
      );
    });

    test('no clock time on a whole-event role reads as whole event', () {
      expect(read(start: null, end: null, standing: true), 'Whole event');
    });

    test('a running-order line with no times has no label', () {
      expect(read(start: null, end: null, standing: false), isNull);
      expect(read(start: start, end: null, standing: false), isNull);
    });

    test('a full range can keep the whole-event prefix', () {
      expect(
        read(start: start, end: end, standing: true),
        '09:00 - 10:30',
      );
      expect(
        read(start: start, end: end, standing: true, prefixWholeEvent: true),
        'Whole event · 09:00 - 10:30',
      );
    });
  });
}
