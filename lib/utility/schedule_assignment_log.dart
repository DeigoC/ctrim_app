import 'package:intl/intl.dart';

import '../models/event/event_program.dart';
import 'schedule_timeline_layout.dart';

/// Stored English update-log line for a post when the people on one
/// programme role change outside the post editor (Ministry Schedule).
///
/// `Updated {subject}: {change}`, for example
/// `Updated Praise and Worship whole-event schedule: added 2 people`.
class ScheduleAssignmentLog {
  ScheduleAssignmentLog._();

  /// Longer role titles are cut with an ellipsis so the line stays short.
  static const int maxTitleLength = 60;

  static const String untitledRole = 'Untitled role';

  static final DateFormat _time = DateFormat('HH:mm');

  /// Null when [before] and [after] name the same people.
  ///
  /// [wholeEvent] is true when the post shows the role in its Whole event
  /// band (see [isWholeEventRole]).
  static String? describe({
    required Map<String, dynamic> role,
    required bool wholeEvent,
    required Iterable<String> before,
    required Iterable<String> after,
  }) {
    final previous = before.toSet();
    final next = after.toSet();
    final added = next.difference(previous).length;
    final removed = previous.difference(next).length;
    if (added == 0 && removed == 0) return null;
    final what = change(added: added, removed: removed, remaining: next.length);
    return 'Updated ${subject(role: role, wholeEvent: wholeEvent)}: $what';
  }

  /// `{title} whole-event schedule`, or `{title} schedule` with its clock
  /// times when it has them.
  static String subject({
    required Map<String, dynamic> role,
    required bool wholeEvent,
  }) {
    final title = _title(role['title']);
    if (wholeEvent) return '$title whole-event schedule';
    final start = role['start'] as DateTime?;
    final end = role['end'] as DateTime?;
    if (start != null && end != null) {
      return '$title schedule (${_time.format(start)}–${_time.format(end)})';
    }
    if (start != null) return '$title schedule (from ${_time.format(start)})';
    return '$title schedule';
  }

  /// [remaining] is how many people are on the role after the change.
  static String change({
    required int added,
    required int removed,
    required int remaining,
  }) {
    if (removed == 0) return 'added ${_people(added)}';
    if (added == 0) {
      if (remaining == 0) return 'removed ${_people(removed)}, now unassigned';
      return 'removed ${_people(removed)}';
    }
    if (added == removed) return 'swapped ${_people(added)}';
    return 'added ${_people(added)}, removed ${_people(removed)}';
  }

  /// True when [roleId] sits in the post's Whole event band: flagged
  /// `standing`, or a long line the timeline lifts out of the running order.
  static bool isWholeEventRole({
    required EventProgram program,
    required int roleId,
  }) {
    final layout = ScheduleTimelineLayout.build(
      roles: program.roles,
      finishTime: program.finishTime,
    );
    return layout.coverageRoles
        .any((coverage) => coverage.role['id'] == roleId);
  }

  static String _people(final int count) =>
      count == 1 ? '1 person' : '$count people';

  static String _title(final Object? raw) {
    final title = (raw is String ? raw : '').trim();
    if (title.isEmpty) return untitledRole;
    if (title.length <= maxTitleLength) return title;
    return '${title.substring(0, maxTitleLength - 1).trimRight()}…';
  }
}
