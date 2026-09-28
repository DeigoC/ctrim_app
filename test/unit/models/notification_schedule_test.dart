import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ctrim_app/models/notification_schedule.dart';

void main() {
  group('NotificationSchedule', () {
    test('creates a day-before reminder with defaults', () {
      final schedule = NotificationSchedule(
        id: 's1',
        postTagId: ' tag-sun ',
        location: ' Belfast ',
        timing: NotificationScheduleTiming.dayBefore,
      );

      expect(schedule.id, 's1');
      expect(schedule.enabled, isTrue);
      expect(schedule.postTagId, 'tag-sun');
      expect(schedule.location, 'Belfast');
      expect(schedule.timing, NotificationScheduleTiming.dayBefore);
      expect(schedule.clockTime, '18:00');
      expect(schedule.hoursBefore, 2);
      expect(schedule.lastSentPostId, isNull);
      expect(schedule.lastError, isNull);
    });

    test('fromMap parses Firestore fields', () {
      final eventAt = DateTime.utc(2026, 10, 4, 9, 30);
      final sentAt = DateTime.utc(2026, 10, 3, 17);
      final schedule = NotificationSchedule.fromMap('abc', {
        'Enabled': true,
        'PostTagId': 'tag-sun',
        'Location': 'North Coast',
        'TimingKind': 'hours_before',
        'ClockTime': '9:05',
        'HoursBefore': 6,
        'LastSentPostId': 'post-1',
        'LastSentEventAt': Timestamp.fromDate(eventAt),
        'LastSentAt': Timestamp.fromDate(sentAt),
        'LastError': ' ',
      });

      expect(schedule.enabled, isTrue);
      expect(schedule.location, 'North Coast');
      expect(schedule.timing, NotificationScheduleTiming.hoursBefore);
      expect(schedule.clockTime, '09:05');
      expect(schedule.hoursBefore, 6);
      expect(schedule.lastSentPostId, 'post-1');
      expect(schedule.lastSentEventAt!.isAtSameMomentAs(eventAt), isTrue);
      expect(schedule.lastSentAt!.isAtSameMomentAs(sentAt), isTrue);
      expect(schedule.lastError, isNull);
    });

    test('fromMap treats an unknown timing as unset and clamps hours', () {
      final schedule = NotificationSchedule.fromMap('abc', {
        'Enabled': false,
        'PostTagId': 'tag',
        'Location': 'Belfast',
        'TimingKind': 'weekly',
        'ClockTime': '99:00',
        'HoursBefore': 0,
      });

      expect(schedule.enabled, isFalse);
      expect(schedule.timing, isNull);
      expect(schedule.clockTime, '18:00');
      expect(schedule.hoursBefore, 1);
    });

    test('toConfigJson omits last-sent fields', () {
      final schedule = NotificationSchedule(
        id: 's1',
        postTagId: 'tag-sun',
        location: 'Belfast',
        timing: NotificationScheduleTiming.morningOf,
        clockTime: '09:00',
        lastSentPostId: 'post-1',
        lastSentEventAt: DateTime.utc(2026, 10, 4, 9, 30),
        lastError: 'failed',
      );

      final config = schedule.toConfigJson();
      expect(config['TimingKind'], 'morning_of');
      expect(config['ClockTime'], '09:00');
      expect(config.containsKey('LastSentPostId'), isFalse);
      expect(config.containsKey('LastError'), isFalse);

      final json = schedule.toJson();
      expect(json['LastSentPostId'], 'post-1');
      expect(json['LastError'], 'failed');
      expect(json['LastSentEventAt'], isA<Timestamp>());
    });
  });
}
