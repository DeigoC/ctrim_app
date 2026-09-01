import '../models/event/event_head.dart';
import 'cell_group_activity_stats.dart';

/// Snapshot of bulletin-linked meeting activity for one cell group.
class CellGroupDetailActivityStats {
  const CellGroupDetailActivityStats({
    required this.pastMeetingsCount,
    required this.pastAttendeesTotal,
    required this.upcomingMeetingsCount,
    required this.averagePastAttendance,
  });

  final int pastMeetingsCount;
  final int pastAttendeesTotal;
  final int upcomingMeetingsCount;
  final double? averagePastAttendance;

  static CellGroupDetailActivityStats empty() => const CellGroupDetailActivityStats(
        pastMeetingsCount: 0,
        pastAttendeesTotal: 0,
        upcomingMeetingsCount: 0,
        averagePastAttendance: null,
      );

  /// Meetings linked to [cellGroupId] in overview snapshot windows.
  factory CellGroupDetailActivityStats.compute({
    required String cellGroupId,
    required List<EventHead> meetings,
    DateTime? now,
  }) {
    final id = cellGroupId.trim();
    if (id.isEmpty) return CellGroupDetailActivityStats.empty();

    final DateTime clock = now ?? DateTime.now();
    final DateTime pastStart = CellGroupActivityStats.pastWindowStart(clock);
    final DateTime upcomingStart = CellGroupActivityStats.upcomingWindowStart(clock);
    final DateTime upcomingEnd =
        CellGroupActivityStats.upcomingWindowEndExclusive(clock);

    int pastMeetings = 0;
    int pastAttendees = 0;
    int upcomingMeetings = 0;

    for (final head in meetings) {
      if (!head.cellGroupIDs.contains(id)) continue;
      final DateTime? eventDate = head.eventDate;
      if (eventDate == null) continue;

      if (!eventDate.isBefore(pastStart) && eventDate.isBefore(upcomingStart)) {
        pastMeetings++;
        pastAttendees += head.attendeeCount;
      } else if (!eventDate.isBefore(upcomingStart) &&
          eventDate.isBefore(upcomingEnd)) {
        upcomingMeetings++;
      }
    }

    return CellGroupDetailActivityStats(
      pastMeetingsCount: pastMeetings,
      pastAttendeesTotal: pastAttendees,
      upcomingMeetingsCount: upcomingMeetings,
      averagePastAttendance:
          pastMeetings == 0 ? null : pastAttendees / pastMeetings,
    );
  }
}
