import 'package:flutter_test/flutter_test.dart';

import 'package:ctrim_app/models/event/event_head.dart';
import 'package:ctrim_app/models/notification_schedule.dart';
import 'package:ctrim_app/utility/notifications/notification_schedule_planner.dart';

void main() {
  final sundayMorning = DateTime.utc(2026, 10, 4, 9, 30);
  final dayBeforeTrigger = DateTime.utc(2026, 10, 3, 17);
  final morningTrigger = DateTime.utc(2026, 10, 4, 8);
  final twoHoursTrigger = DateTime.utc(2026, 10, 4, 7, 30);

  EventHead head({
    String id = 'post-1',
    String title = 'Sunday Worship',
    String location = 'Belfast',
    List<String> tagIDs = const ['tag-sun'],
    DateTime? eventDate,
    bool periodParent = false,
  }) {
    final created = EventHead(
      id: id,
      title: title,
      location: location,
      tagIDs: tagIDs,
      isPeriodParent: periodParent,
    );
    if (eventDate != null) created.setEventDate(eventDate);
    return created;
  }

  NotificationSchedule schedule({
    NotificationScheduleTiming timing = NotificationScheduleTiming.dayBefore,
    String clockTime = '18:00',
    int hoursBefore = 2,
    String? lastSentPostId,
    DateTime? lastSentEventAt,
    String location = 'Belfast',
    String postTagId = 'tag-sun',
  }) {
    return NotificationSchedule(
      id: 's1',
      postTagId: postTagId,
      location: location,
      timing: timing,
      clockTime: clockTime,
      hoursBefore: hoursBefore,
      lastSentPostId: lastSentPostId,
      lastSentEventAt: lastSentEventAt,
    );
  }

  group('NotificationSchedulePlanner', () {
    test('day before at 18:00 London is 17:00 UTC during BST', () {
      final trigger = NotificationSchedulePlanner.triggerAt(
        schedule: schedule(),
        eventDate: sundayMorning,
      );

      expect(trigger, dayBeforeTrigger);
      expect(
        NotificationSchedulePlanner.formatWhen(trigger!),
        'Sat, Oct 3 · 18:00',
      );
    });

    test('day before at 18:00 London stays 18:00 UTC in winter', () {
      final winterSunday = DateTime.utc(2026, 11, 1, 10, 30);
      final trigger = NotificationSchedulePlanner.triggerAt(
        schedule: schedule(),
        eventDate: winterSunday,
      );

      expect(trigger, DateTime.utc(2026, 10, 31, 18));
      expect(
        NotificationSchedulePlanner.comingUpBody(winterSunday),
        'Coming up · Sun, Nov 1 · 10:30',
      );
    });

    test('morning of 09:00 is before a 10:30 start', () {
      final row = schedule(
        timing: NotificationScheduleTiming.morningOf,
        clockTime: '09:00',
      );

      expect(
        NotificationSchedulePlanner.triggerAt(
          schedule: row,
          eventDate: sundayMorning,
        ),
        morningTrigger,
      );
      expect(
        NotificationSchedulePlanner.morningOfAfterStart(
          schedule: row,
          eventDate: sundayMorning,
        ),
        isFalse,
      );
    });

    test('morning of after the start does not fire', () {
      final row = schedule(
        timing: NotificationScheduleTiming.morningOf,
        clockTime: '11:00',
      );
      final post = head(eventDate: sundayMorning);

      expect(
        NotificationSchedulePlanner.triggerAt(
          schedule: row,
          eventDate: sundayMorning,
        ),
        isNull,
      );
      expect(
        NotificationSchedulePlanner.dueHead(
          schedule: row,
          heads: [post],
          now: DateTime.utc(2026, 10, 4, 10),
        ),
        isNull,
      );

      final preview = NotificationSchedulePlanner.preview(
        schedule: row,
        heads: [post],
        now: DateTime.utc(2026, 10, 4, 8),
      );
      expect(preview?.morningOfAfterStart, isTrue);
      expect(preview?.head.id, 'post-1');
    });

    test('hours before subtracts from the event instant', () {
      expect(
        NotificationSchedulePlanner.triggerAt(
          schedule: schedule(
            timing: NotificationScheduleTiming.hoursBefore,
            hoursBefore: 2,
          ),
          eventDate: sundayMorning,
        ),
        twoHoursTrigger,
      );
      expect(
        NotificationSchedulePlanner.comingUpBody(sundayMorning),
        'Coming up · Sun, Oct 4 · 10:30',
      );
    });

    test('a missed tick still sends until the event starts', () {
      final row = schedule();
      final post = head(eventDate: sundayMorning);

      expect(
        NotificationSchedulePlanner.dueHead(
          schedule: row,
          heads: [post],
          now: dayBeforeTrigger,
        )?.id,
        'post-1',
      );
      expect(
        NotificationSchedulePlanner.dueHead(
          schedule: row,
          heads: [post],
          now: dayBeforeTrigger.subtract(const Duration(minutes: 1)),
        ),
        isNull,
      );
      expect(
        NotificationSchedulePlanner.dueHead(
          schedule: row,
          heads: [post],
          now: sundayMorning.subtract(const Duration(minutes: 1)),
        )?.id,
        'post-1',
      );
      expect(
        NotificationSchedulePlanner.dueHead(
          schedule: row,
          heads: [post],
          now: sundayMorning,
        ),
        isNull,
      );
    });

    test('already sent for this post and event date is not due', () {
      final row = schedule(
        lastSentPostId: 'post-1',
        lastSentEventAt: sundayMorning,
      );

      expect(
        NotificationSchedulePlanner.dueHead(
          schedule: row,
          heads: [head(eventDate: sundayMorning)],
          now: dayBeforeTrigger,
        ),
        isNull,
      );
    });

    test('period parents and other locations are ignored', () {
      final row = schedule();
      final now = dayBeforeTrigger;

      expect(
        NotificationSchedulePlanner.dueHead(
          schedule: row,
          heads: [
            head(id: 'parent', eventDate: sundayMorning, periodParent: true),
            head(
              id: 'elsewhere',
              location: 'Portadown',
              eventDate: sundayMorning,
            ),
          ],
          now: now,
        ),
        isNull,
      );
    });

    test('the soonest due post wins, then the next one after it was sent', () {
      final earlier = head(
        id: 'early',
        eventDate: sundayMorning,
      );
      final later = head(
        id: 'later',
        title: 'Evening',
        eventDate: sundayMorning.add(const Duration(hours: 1)),
      );
      final row = schedule(
        timing: NotificationScheduleTiming.hoursBefore,
        hoursBefore: 2,
      );
      final now = twoHoursTrigger;

      expect(
        NotificationSchedulePlanner.dueHead(
          schedule: row,
          heads: [later, earlier],
          now: now,
        )?.id,
        'early',
      );

      final sent = schedule(
        timing: NotificationScheduleTiming.hoursBefore,
        hoursBefore: 2,
        lastSentPostId: 'early',
        lastSentEventAt: sundayMorning,
      );
      expect(
        NotificationSchedulePlanner.dueHead(
          schedule: sent,
          heads: [later, earlier],
          now: now.add(const Duration(hours: 1)),
        )?.id,
        'later',
      );

      final preview = NotificationSchedulePlanner.preview(
        schedule: sent,
        heads: [earlier, later],
        now: now,
      );
      expect(preview?.head.id, 'later');
    });
  });
}
