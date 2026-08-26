import 'package:intl/intl.dart';

/// How the broadcast notification body is chosen on the compose page.
enum BroadcastBodySource {
  subtitle,
  preset,
  custom,
}

/// Builds reminder-style notification copy from post title / subtitle / event date.
///
/// Keeps the stored post subtitle free for in-app description while broadcasts
/// can use dedicated upcoming-event wording.
abstract final class EventNotificationCopy {
  static final DateFormat _dateFormat = DateFormat('EEE, MMM d');
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _dateTimeFormat = DateFormat('EEE, MMM d · HH:mm');

  /// Default body source: reminder preset when the event is still upcoming.
  static BroadcastBodySource defaultSource({
    required String subtitle,
    DateTime? eventDate,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    if (eventDate != null && eventDate.isAfter(clock)) {
      return BroadcastBodySource.preset;
    }
    if (subtitle.trim().isNotEmpty) {
      return BroadcastBodySource.subtitle;
    }
    return BroadcastBodySource.custom;
  }

  static String formatEventDateTime(DateTime eventDate) =>
      _dateTimeFormat.format(eventDate);

  static String formatEventDate(DateTime eventDate) =>
      _dateFormat.format(eventDate);

  static String formatEventTime(DateTime eventDate) =>
      _timeFormat.format(eventDate);

  /// Relative phrase such as "In 3 days" or "In 2 hours".
  static String relativePhrase(DateTime eventDate, {DateTime? now}) {
    final clock = now ?? DateTime.now();
    final duration = eventDate.difference(clock);

    if (duration.isNegative) {
      final absD = duration.abs();
      if (absD.inDays > 0) return '${absD.inDays} days ago';
      if (absD.inHours > 0) return '${absD.inHours} hours ago';
      return '${absD.inMinutes} minutes ago';
    }
    if (duration.inDays > 0) return 'In ${duration.inDays} days';
    if (duration.inHours > 0) return 'In ${duration.inHours} hours';
    return 'In ${duration.inMinutes} minutes';
  }

  /// Preset bodies for the compose page. Includes reminder lines when [eventDate]
  /// is set; otherwise a couple of generic update lines.
  static List<String> presetBodies({
    required String title,
    DateTime? eventDate,
    DateTime? now,
  }) {
    if (eventDate == null) {
      return const [
        'Check out this update',
        'Something new for you',
        'Take a look at this post',
      ];
    }

    final when = formatEventDateTime(eventDate);
    final dateOnly = formatEventDate(eventDate);
    final timeOnly = formatEventTime(eventDate);
    final relative = relativePhrase(eventDate, now: now);

    return [
      'Coming up · $when',
      'Reminder: this event is on $dateOnly at $timeOnly',
      "Don't forget — $when",
      '$relative · $when',
      'Join us for $title · $when',
    ];
  }

  /// Resolves the body text for the selected source.
  static String resolveBody({
    required BroadcastBodySource source,
    required String subtitle,
    required String customBody,
    required String selectedPreset,
  }) {
    switch (source) {
      case BroadcastBodySource.subtitle:
        return subtitle.trim();
      case BroadcastBodySource.preset:
        return selectedPreset.trim();
      case BroadcastBodySource.custom:
        return customBody.trim();
    }
  }
}
