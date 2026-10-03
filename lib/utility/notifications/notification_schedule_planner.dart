import '../../models/event/event_head.dart';
import '../../models/notification_schedule.dart';
import 'london_time.dart';

/// What the hub shows for the next post a schedule could announce.
class SchedulePreview {
  const SchedulePreview({
    required this.head,
    required this.trigger,
    required this.morningOfAfterStart,
  });

  final EventHead head;

  /// When the notification will send. Null when [morningOfAfterStart] is set.
  final DateTime? trigger;

  /// The morning-of clock is at or after this post's start, so it will not send.
  final bool morningOfAfterStart;
}

/// Decides when a [NotificationSchedule] sends, and which upcoming post is due.
///
/// Clock rules use Europe/London. A missed tick still sends until the event
/// starts. One post per schedule: the soonest due event date.
class NotificationSchedulePlanner {
  NotificationSchedulePlanner._();

  static const Duration lookback = Duration(hours: 1);
  static const Duration functionLookahead = Duration(days: 3);

  /// Hub preview window. Wider than the function so next Sunday is visible
  /// mid-week. The function still only queries [functionLookahead].
  static const Duration previewLookahead = Duration(days: 14);

  /// `Coming up · Sun, Oct 4 · 10:30` in Europe/London.
  static String comingUpBody(DateTime eventDate) =>
      'Coming up · ${LondonTime.format(eventDate)}';

  /// Push body for a scheduled reminder. Matches `reminder_body` in
  /// `functions/notification_schedule.py`: subtitle, then the start time.
  static String reminderBody(EventHead head) {
    final eventDate = head.eventDate;
    final when = eventDate == null ? '' : comingUpBody(eventDate);
    final subtitle = head.subtitle.trim();
    if (subtitle.isNotEmpty && when.isNotEmpty) return '$subtitle\n$when';
    return subtitle.isNotEmpty ? subtitle : when;
  }

  static String formatWhen(DateTime instant) => LondonTime.format(instant);

  /// Trigger instant, or null when this timing cannot fire for [eventDate].
  ///
  /// Morning-of is null when the chosen clock is at or after the event start.
  static DateTime? triggerAt({
    required NotificationSchedule schedule,
    required DateTime eventDate,
  }) {
    final timing = schedule.timing;
    if (timing == null) return null;
    if (timing == NotificationScheduleTiming.hoursBefore) {
      return eventDate.toUtc().subtract(Duration(hours: schedule.hoursBefore));
    }

    final clock = _parseClock(schedule.clockTime);
    if (clock == null) return null;
    final wall = LondonTime.wall(eventDate);
    if (timing == NotificationScheduleTiming.dayBefore) {
      final previous = DateTime.utc(wall.year, wall.month, wall.day)
          .subtract(const Duration(days: 1));
      return LondonTime.wallToUtc(
        year: previous.year,
        month: previous.month,
        day: previous.day,
        hour: clock.$1,
        minute: clock.$2,
      );
    }

    final morning = LondonTime.wallToUtc(
      year: wall.year,
      month: wall.month,
      day: wall.day,
      hour: clock.$1,
      minute: clock.$2,
    );
    if (morning == null) return null;
    if (!morning.isBefore(eventDate.toUtc())) return null;
    return morning;
  }

  static bool morningOfAfterStart({
    required NotificationSchedule schedule,
    required DateTime eventDate,
  }) {
    if (schedule.timing != NotificationScheduleTiming.morningOf) return false;
    return triggerAt(schedule: schedule, eventDate: eventDate) == null &&
        _parseClock(schedule.clockTime) != null;
  }

  static bool alreadySent({
    required NotificationSchedule schedule,
    required String postId,
    required DateTime eventDate,
  }) {
    if (schedule.lastSentPostId != postId) return false;
    final sentAt = schedule.lastSentEventAt;
    if (sentAt == null) return false;
    return sentAt.toUtc().difference(eventDate.toUtc()).inSeconds.abs() < 1;
  }

  static List<EventHead> matchingHeads({
    required NotificationSchedule schedule,
    required Iterable<EventHead> heads,
  }) {
    final tagId = schedule.postTagId.trim();
    final location = schedule.location.trim();
    if (tagId.isEmpty || location.isEmpty) return const [];
    return [
      for (final head in heads)
        if (_matches(head, tagId: tagId, location: location)) head,
    ];
  }

  /// Soonest post that should send on this tick. Null when nothing is due.
  static EventHead? dueHead({
    required NotificationSchedule schedule,
    required Iterable<EventHead> heads,
    required DateTime now,
  }) {
    EventHead? best;
    for (final head in matchingHeads(schedule: schedule, heads: heads)) {
      final eventDate = head.eventDate;
      if (eventDate == null) continue;
      final trigger = triggerAt(schedule: schedule, eventDate: eventDate);
      if (trigger == null) continue;
      if (!now.toUtc().isBefore(eventDate.toUtc())) continue;
      if (now.toUtc().isBefore(trigger)) continue;
      if (alreadySent(
        schedule: schedule,
        postId: head.id,
        eventDate: eventDate,
      )) {
        continue;
      }
      if (best == null || eventDate.isBefore(best.eventDate!)) {
        best = head;
      }
    }
    return best;
  }

  /// Next post the hub should describe. Skips posts already sent for this row.
  static SchedulePreview? preview({
    required NotificationSchedule schedule,
    required Iterable<EventHead> heads,
    required DateTime now,
  }) {
    final upcoming =
        matchingHeads(schedule: schedule, heads: heads).where((head) {
      final eventDate = head.eventDate;
      return eventDate != null && eventDate.toUtc().isAfter(now.toUtc());
    }).toList()
          ..sort((a, b) => a.eventDate!.compareTo(b.eventDate!));

    for (final head in upcoming) {
      final eventDate = head.eventDate!;
      if (morningOfAfterStart(schedule: schedule, eventDate: eventDate)) {
        return SchedulePreview(
          head: head,
          trigger: null,
          morningOfAfterStart: true,
        );
      }
      final trigger = triggerAt(schedule: schedule, eventDate: eventDate);
      if (trigger == null) continue;
      if (alreadySent(
        schedule: schedule,
        postId: head.id,
        eventDate: eventDate,
      )) {
        continue;
      }
      return SchedulePreview(
        head: head,
        trigger: trigger,
        morningOfAfterStart: false,
      );
    }
    return null;
  }

  static bool _matches(
    EventHead head, {
    required String tagId,
    required String location,
  }) {
    if (head.isPeriodParent) return false;
    if (head.eventDate == null) return false;
    if (head.location.trim() != location) return false;
    return head.hasTag(tagId);
  }

  static (int, int)? _parseClock(String raw) {
    final match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(raw.trim());
    if (match == null) return null;
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return (hour, minute);
  }
}
