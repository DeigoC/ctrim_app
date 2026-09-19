import '../firebase/db_managers/cell_group_db_manager.dart';
import '../firebase/db_managers/event_db_manager.dart';
import '../models/cell_group.dart';
import '../models/event/event_attendance.dart';
import '../models/event/event_head.dart';
import '../models/user.dart';

/// One past cell-group meeting and how [user] took part.
class UserCellGroupMeetingAttendance {
  const UserCellGroupMeetingAttendance({
    required this.head,
    required this.attended,
    this.hosted = false,
  });

  final EventHead head;

  /// Checked in as a guest / attendee on the post.
  final bool attended;

  /// Listed leader of a cell group linked to this meeting (not a guest).
  final bool hosted;

  bool get participated => attended || hosted;
}

/// Attendance snapshot for a user across their cell groups' past meetings.
class UserCellGroupAttendanceSummary {
  const UserCellGroupAttendanceSummary({
    required this.attendedInPastWindow,
    this.lastAttendedDate,
    this.lastAttendedMeeting,
    this.meetingsInWindow = 0,
    this.meetingsAttended = 0,
    this.meetingsHosted = 0,
    this.meetingsParticipated = 0,
    this.distinctGroupsAttended = 0,
    this.recentMeetings = const [],
  });

  final bool attendedInPastWindow;
  final DateTime? lastAttendedDate;
  final EventHead? lastAttendedMeeting;
  final int meetingsInWindow;

  /// Guest / attendee check-ins in the window.
  final int meetingsAttended;

  /// Meetings where the user led a linked cell group.
  final int meetingsHosted;

  /// Distinct meetings the user attended as a guest or hosted.
  final int meetingsParticipated;

  /// Distinct cell group IDs the user checked in at or hosted during the window.
  final int distinctGroupsAttended;

  /// Past-window meetings for this member, newest first.
  final List<UserCellGroupMeetingAttendance> recentMeetings;
}

/// Profile helper: did [user] take part in a linked CG meeting in the past 3 weeks?
///
/// Guest check-ins live on the post attendance list. Listed cell-group leaders
/// (hosts) are not guests, but still count as having been part of the meeting.
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

  /// Catalogue groups [user] is listed as a leader/host of.
  static Set<String> ledGroupIdsFor({
    required User user,
    required Iterable<CellGroup> groups,
  }) {
    final ids = <String>{};
    final authId = user.authID.trim();
    for (final group in groups) {
      if (group.isLeaderUser(user.id) ||
          (authId.isNotEmpty && group.isLeaderAuth(authId))) {
        ids.add(group.id);
      }
    }
    return ids;
  }

  /// Pure summary from already-fetched meetings and attendance docs.
  static UserCellGroupAttendanceSummary summarize({
    required String userId,
    required List<EventHead> memberMeetings,
    required Map<String, EventAttendance> attendanceByPostId,
    Set<String> memberGroupIds = const {},
    Set<String> ledGroupIds = const {},
  }) {
    if (memberMeetings.isEmpty) {
      return const UserCellGroupAttendanceSummary(attendedInPastWindow: false);
    }

    var meetingsAttended = 0;
    var meetingsHosted = 0;
    var meetingsParticipated = 0;
    DateTime? lastAttended;
    EventHead? lastMeeting;
    final groupsAttended = <String>{};
    final recent = <UserCellGroupMeetingAttendance>[];

    for (final head in memberMeetings) {
      final attendance = attendanceByPostId[head.id];
      final attended = attendance != null && attendance.hasUserAttendee(userId);
      final hosted = head.cellGroupIDs.any(ledGroupIds.contains);
      recent.add(
        UserCellGroupMeetingAttendance(
          head: head,
          attended: attended,
          hosted: hosted,
        ),
      );
      if (!attended && !hosted) continue;

      meetingsParticipated++;
      if (attended) meetingsAttended++;
      if (hosted) meetingsHosted++;
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

    // Newest first for profile history.
    recent.sort((a, b) {
      final aDate = a.head.eventDate;
      final bDate = b.head.eventDate;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });

    return UserCellGroupAttendanceSummary(
      attendedInPastWindow: meetingsParticipated > 0,
      lastAttendedDate: lastAttended,
      lastAttendedMeeting: lastMeeting,
      meetingsInWindow: memberMeetings.length,
      meetingsAttended: meetingsAttended,
      meetingsHosted: meetingsHosted,
      meetingsParticipated: meetingsParticipated,
      distinctGroupsAttended: groupsAttended.length,
      recentMeetings: recent,
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
    final ledGroupIds = ledGroupIdsFor(user: user, groups: memberGroups);
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
      ledGroupIds: ledGroupIds,
    );
  }
}
