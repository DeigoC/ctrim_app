import '../firebase/db_managers/cell_group_db_manager.dart';
import '../firebase/db_managers/event_db_manager.dart';
import '../models/cell_group.dart';
import '../models/event/event_attendance.dart';
import '../models/event/event_head.dart';
import '../models/user.dart';

/// Attendance snapshot for a user across their cell groups' past meetings.
class UserCellGroupAttendanceSummary {
  const UserCellGroupAttendanceSummary({
    required this.attendedInPastWindow,
    this.lastAttendedDate,
    this.lastAttendedMeeting,
    this.meetingsInWindow = 0,
    this.meetingsAttended = 0,
    this.distinctGroupsAttended = 0,
  });

  final bool attendedInPastWindow;
  final DateTime? lastAttendedDate;
  final EventHead? lastAttendedMeeting;
  final int meetingsInWindow;
  final int meetingsAttended;

  /// Distinct cell group IDs the user checked in at during the window.
  final int distinctGroupsAttended;
}

/// Profile helper: did [user] check in at a linked CG meeting in the past 3 weeks?
abstract final class UserCellGroupAttendance {
  /// Past meetings linked to any of [memberGroupIds], soonest first.
  static List<EventHead> meetingsForMemberGroups({
    required List<EventHead> pastMeetings,
    required Set<String> memberGroupIds,
  }) {
    if (memberGroupIds.isEmpty) return const [];

    final rows = pastMeetings
        .where((head) =>
            head.eventDate != null &&
            head.cellGroupIDs.any(memberGroupIds.contains))
        .toList();

    rows.sort((a, b) {
      final aDate = a.eventDate;
      final bDate = b.eventDate;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return aDate.compareTo(bDate);
    });

    return rows;
  }

  /// Pure summary from already-fetched meetings and attendance docs.
  static UserCellGroupAttendanceSummary summarize({
    required String userId,
    required List<EventHead> memberMeetings,
    required Map<String, EventAttendance> attendanceByPostId,
    Set<String> memberGroupIds = const {},
  }) {
    if (memberMeetings.isEmpty) {
      return const UserCellGroupAttendanceSummary(attendedInPastWindow: false);
    }

    var meetingsAttended = 0;
    DateTime? lastAttended;
    EventHead? lastMeeting;
    final groupsAttended = <String>{};

    for (final head in memberMeetings) {
      final attendance = attendanceByPostId[head.id];
      if (attendance == null || !attendance.hasUserAttendee(userId)) {
        continue;
      }
      meetingsAttended++;
      for (final groupId in head.cellGroupIDs) {
        if (memberGroupIds.isEmpty || memberGroupIds.contains(groupId)) {
          groupsAttended.add(groupId);
        }
      }
      final date = head.eventDate;
      if (date != null &&
          (lastAttended == null || date.isAfter(lastAttended))) {
        lastAttended = date;
        lastMeeting = head;
      }
    }

    return UserCellGroupAttendanceSummary(
      attendedInPastWindow: meetingsAttended > 0,
      lastAttendedDate: lastAttended,
      lastAttendedMeeting: lastMeeting,
      meetingsInWindow: memberMeetings.length,
      meetingsAttended: meetingsAttended,
      distinctGroupsAttended: groupsAttended.length,
    );
  }

  /// Loads past-window attendance for [user]'s [memberGroups].
  ///
  /// Returns an empty summary when [memberGroups] is empty. Attendance docs
  /// require a signed-in session (Firestore rules).
  static Future<UserCellGroupAttendanceSummary> load({
    required User user,
    required List<CellGroup> memberGroups,
    CellGroupDBManager? dbManager,
    DateTime? now,
  }) async {
    if (memberGroups.isEmpty) {
      return const UserCellGroupAttendanceSummary(attendedInPastWindow: false);
    }

    final db = dbManager ?? CellGroupDBManager();
    final memberGroupIds = memberGroups.map((g) => g.id).toSet();
    final pastMeetings = await db.fetchPastLinkedMeetings(now: now);
    final memberMeetings = meetingsForMemberGroups(
      pastMeetings: pastMeetings,
      memberGroupIds: memberGroupIds,
    );

    if (memberMeetings.isEmpty) {
      return const UserCellGroupAttendanceSummary(
        attendedInPastWindow: false,
        meetingsInWindow: 0,
      );
    }

    final attendanceByPostId = <String, EventAttendance>{};
    await Future.wait(
      memberMeetings.map((head) async {
        final attendance =
            await EventSupplementalDBManager(head.id).fetchAttendance();
        attendanceByPostId[head.id] = attendance;
      }),
    );

    return summarize(
      userId: user.id,
      memberMeetings: memberMeetings,
      attendanceByPostId: attendanceByPostId,
      memberGroupIds: memberGroupIds,
    );
  }
}
