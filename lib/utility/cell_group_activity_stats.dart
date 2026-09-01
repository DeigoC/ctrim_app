import '../models/cell_group.dart';
import '../models/event/event_head.dart';

/// Rolling windows for the Cell Groups overview activity dashboard.
class CellGroupActivityWindows {
  /// Inclusive lookback for past meetings (days before local midnight today).
  static const int pastDays = 21;

  /// Inclusive lookahead from local midnight today (today + next 6 days).
  static const int upcomingDays = 7;

  /// Lookback for weekly activity charts (matches church-hub window).
  static const int chartPastDays = 90;

  const CellGroupActivityWindows._();
}

/// Snapshot of cell-group activity derived from catalogue heads + linked posts.
///
/// Computed on read from existing denorms ([EventHead.attendeeCount],
/// [EventHead.eventDate], [EventHead.cellGroupIDs], [CellGroup.memberCount]).
/// No separate `cg-statistics` document is required at current scale.
class CellGroupActivityStats {
  const CellGroupActivityStats({
    required this.pastMeetingsCount,
    required this.pastAttendeesTotal,
    required this.upcomingMeetingsCount,
    required this.distinctGroupsMetPast,
    required this.activeGroupsCount,
    required this.pausedGroupsCount,
    required this.totalActiveMembers,
    required this.averagePastAttendance,
  });

  /// CG-linked bulletin posts with [EventHead.eventDate] in the past window.
  final int pastMeetingsCount;

  /// Sum of [EventHead.attendeeCount] for [pastMeetingsCount] meetings.
  final int pastAttendeesTotal;

  /// CG-linked posts dated from local today through the upcoming window.
  final int upcomingMeetingsCount;

  /// Distinct cell group IDs that appear on past-window meetings.
  final int distinctGroupsMetPast;

  final int activeGroupsCount;
  final int pausedGroupsCount;

  /// Sum of [CellGroup.memberCount] for non-archived active groups.
  final int totalActiveMembers;

  /// [pastAttendeesTotal] / [pastMeetingsCount], or null when no past meetings.
  final double? averagePastAttendance;

  static CellGroupActivityStats empty() => const CellGroupActivityStats(
        pastMeetingsCount: 0,
        pastAttendeesTotal: 0,
        upcomingMeetingsCount: 0,
        distinctGroupsMetPast: 0,
        activeGroupsCount: 0,
        pausedGroupsCount: 0,
        totalActiveMembers: 0,
        averagePastAttendance: null,
      );

  /// Local calendar day for [date] (midnight).
  static DateTime dayStart(final DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Past window: [[today] - pastDays, [today]) — excludes today.
  static DateTime pastWindowStart(final DateTime now) =>
      dayStart(now).subtract(const Duration(days: CellGroupActivityWindows.pastDays));

  /// Upcoming window start: local midnight today (inclusive).
  static DateTime upcomingWindowStart(final DateTime now) => dayStart(now);

  /// Exclusive end of upcoming window (day after last included day).
  static DateTime upcomingWindowEndExclusive(final DateTime now) =>
      dayStart(now).add(const Duration(days: CellGroupActivityWindows.upcomingDays));

  /// Start of the chart lookback (local midnight).
  static DateTime chartPastWindowStart(final DateTime now) => dayStart(now)
      .subtract(const Duration(days: CellGroupActivityWindows.chartPastDays));

  /// Inclusive Firestore range start for a single query covering chart past +
  /// upcoming snapshot windows.
  static DateTime queryRangeStart(final DateTime now) =>
      chartPastWindowStart(now);

  /// Exclusive Firestore range end covering past + upcoming.
  static DateTime queryRangeEndExclusive(final DateTime now) =>
      upcomingWindowEndExclusive(now);

  /// Past-only window for weekly charts: [chartPastWindowStart, today).
  static DateTime chartWindowEndExclusive(final DateTime now) =>
      upcomingWindowStart(now);

  /// Builds stats from catalogue [groups] and CG-linked [meetings].
  ///
  /// [meetings] should already be filtered to posts with non-empty
  /// [EventHead.cellGroupIDs]; heads without [EventHead.eventDate] are ignored.
  factory CellGroupActivityStats.compute({
    required List<CellGroup> groups,
    required List<EventHead> meetings,
    DateTime? now,
  }) {
    final DateTime clock = now ?? DateTime.now();
    final DateTime pastStart = pastWindowStart(clock);
    final DateTime upcomingStart = upcomingWindowStart(clock);
    final DateTime upcomingEnd = upcomingWindowEndExclusive(clock);

    int pastMeetings = 0;
    int pastAttendees = 0;
    int upcomingMeetings = 0;
    final Set<String> groupsMet = <String>{};

    for (final head in meetings) {
      final DateTime? eventDate = head.eventDate;
      if (eventDate == null) continue;
      if (head.cellGroupIDs.isEmpty) continue;

      if (!eventDate.isBefore(pastStart) && eventDate.isBefore(upcomingStart)) {
        pastMeetings++;
        pastAttendees += head.attendeeCount;
        groupsMet.addAll(head.cellGroupIDs);
      } else if (!eventDate.isBefore(upcomingStart) &&
          eventDate.isBefore(upcomingEnd)) {
        upcomingMeetings++;
      }
    }

    int active = 0;
    int paused = 0;
    int members = 0;
    for (final group in groups) {
      if (group.isArchived) continue;
      if (group.isActive) {
        active++;
        members += group.memberCount;
      } else if (group.isPaused) {
        paused++;
      }
    }

    return CellGroupActivityStats(
      pastMeetingsCount: pastMeetings,
      pastAttendeesTotal: pastAttendees,
      upcomingMeetingsCount: upcomingMeetings,
      distinctGroupsMetPast: groupsMet.length,
      activeGroupsCount: active,
      pausedGroupsCount: paused,
      totalActiveMembers: members,
      averagePastAttendance:
          pastMeetings == 0 ? null : pastAttendees / pastMeetings,
    );
  }
}
