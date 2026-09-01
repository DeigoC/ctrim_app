import '../firebase/db_managers/cell_group_db_manager.dart';
import '../models/cell_group.dart';
import '../models/event/event_head.dart';
import '../models/user.dart';
import 'cell_group_roster_cache.dart';

/// One upcoming cell-group meeting row for the Personal home dashboard.
class PersonalCellGroupMeetingPreview {
  const PersonalCellGroupMeetingPreview({
    required this.head,
    required this.group,
  });

  final EventHead head;
  final CellGroup group;
}

/// Snapshot for the Personal cell groups dashboard card.
class PersonalCellGroupPreviewData {
  const PersonalCellGroupPreviewData({
    required this.memberGroups,
    required this.upcomingMeetings,
    required this.totalUpcomingCount,
  });

  final List<CellGroup> memberGroups;
  final List<PersonalCellGroupMeetingPreview> upcomingMeetings;
  final int totalUpcomingCount;
}

/// Default upcoming lookahead for Personal home (8 weeks).
const int personalCellGroupMeetingLookaheadDays = 56;

/// Personal home cell-group meeting preview logic (testable without Firestore).
abstract final class PersonalCellGroupMeetings {
  /// Loads membership and upcoming meetings for [user].
  static Future<PersonalCellGroupPreviewData> load({
    required User user,
    required Iterable<CellGroup> catalogue,
    CellGroupDBManager? dbManager,
    DateTime? now,
    int lookaheadDays = personalCellGroupMeetingLookaheadDays,
    int previewLimit = 3,
  }) async {
    final activeGroups = catalogue.where((g) => !g.isArchived).toList();
    final activeIds = activeGroups.map((g) => g.id);
    await CellGroupRosterCache.ensureLoaded(activeIds);

    final memberGroups = CellGroupRosterCache.groupsForUser(
      user: user,
      catalogue: catalogue,
    );

    if (memberGroups.isEmpty) {
      return const PersonalCellGroupPreviewData(
        memberGroups: [],
        upcomingMeetings: [],
        totalUpcomingCount: 0,
      );
    }

    final memberGroupIds = memberGroups.map((g) => g.id).toSet();
    final db = dbManager ?? CellGroupDBManager();
    final meetings = await db.fetchUpcomingLinkedMeetings(
      now: now,
      lookaheadDays: lookaheadDays,
    );

    final filtered = meetingsForMember(
      meetings: meetings,
      memberGroupIds: memberGroupIds,
      memberGroups: memberGroups,
    );

    final total = filtered.length;
    final preview = filtered.length <= previewLimit
        ? filtered
        : filtered.sublist(0, previewLimit);

    return PersonalCellGroupPreviewData(
      memberGroups: memberGroups,
      upcomingMeetings: preview,
      totalUpcomingCount: total,
    );
  }

  /// Filters [meetings] to those linked to [memberGroupIds], sorted soonest first.
  static List<PersonalCellGroupMeetingPreview> meetingsForMember({
    required List<EventHead> meetings,
    required Set<String> memberGroupIds,
    required List<CellGroup> memberGroups,
  }) {
    if (memberGroupIds.isEmpty) return const [];

    final groupById = {for (final g in memberGroups) g.id: g};
    final rows = <PersonalCellGroupMeetingPreview>[];

    for (final head in meetings) {
      final eventDate = head.eventDate;
      if (eventDate == null) continue;

      final matchingIds = head.cellGroupIDs
          .where((id) => memberGroupIds.contains(id))
          .toList();
      if (matchingIds.isEmpty) continue;

      matchingIds.sort((a, b) {
        final nameA = groupById[a]?.name ?? a;
        final nameB = groupById[b]?.name ?? b;
        return nameA.toLowerCase().compareTo(nameB.toLowerCase());
      });

      final group = groupById[matchingIds.first];
      if (group == null) continue;

      rows.add(PersonalCellGroupMeetingPreview(head: head, group: group));
    }

    rows.sort((a, b) {
      final aDate = a.head.eventDate;
      final bDate = b.head.eventDate;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return aDate.compareTo(bDate);
    });

    return rows;
  }

  /// First resolved leader for [group] from [users] (list-tab pattern).
  static User? primaryLeaderForGroup({
    required CellGroup group,
    required Iterable<User> users,
  }) {
    for (final uid in group.leaderUserIds) {
      for (final user in users) {
        if (user.id == uid) return user;
      }
    }
    return null;
  }

  /// Display name for a group leader, never a raw uid.
  static String leaderDisplayName({
    required CellGroup group,
    required Iterable<User> users,
    required String fallbackLabel,
  }) {
    final leader = primaryLeaderForGroup(group: group, users: users);
    if (leader == null) return fallbackLabel;
    final name = leader.fullname.trim();
    return name.isEmpty ? fallbackLabel : name;
  }
}
