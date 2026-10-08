import '../models/event/event_head.dart';
import '../models/event/event_program.dart';
import '../models/user.dart';
import '../models/user_tag.dart';
import 'catalog/volunteer_locations.dart';

/// One post on the personal team rota, with the programme roles that match
/// the selected team tags.
class TeamRotaPost {
  const TeamRotaPost({
    required this.head,
    required this.roles,
  });

  final EventHead head;
  final List<Map<String, dynamic>> roles;
}

/// Posts grouped under a calendar month (for section headers).
class TeamRotaMonthGroup {
  const TeamRotaMonthGroup({
    required this.year,
    required this.month,
    required this.posts,
  });

  final int year;
  final int month;
  final List<TeamRotaPost> posts;

  DateTime get monthDate => DateTime(year, month);
}

/// Filter and group dated posts into a team rota.
///
/// Join is role [EventProgram.tagIDsOf] vs selected team-tag IDs — not the
/// assignee's personal tags. Untagged roles are omitted. Empty [selectedTagIDs]
/// means no ministry filter (all tagged roles). Empty `uids` still belong to
/// the team.
class TeamRotaQuery {
  TeamRotaQuery._();

  static const int defaultHorizonMonths = 3;

  /// Roles a card shows before it offers to expand.
  static const int previewRoleCount = 4;

  /// Cards with this many roles or fewer stay fully open.
  static const int collapseAfterRoleCount = 5;

  /// How many roles to paint. Lists longer than [collapseAfterRoleCount]
  /// show [previewRoleCount] until the card is expanded.
  static int visibleRoleCount({
    required int total,
    required bool expanded,
  }) {
    if (expanded || total <= collapseAfterRoleCount) return total;
    return previewRoleCount;
  }

  static DateTime rangeStart(final DateTime now) =>
      DateTime(now.year, now.month, now.day);

  static DateTime rangeEndExclusive(
    final DateTime now, {
    int months = defaultHorizonMonths,
  }) {
    return DateTime(now.year, now.month + months, now.day);
  }

  static List<String> uidsOf(final Map<String, dynamic> role) {
    final raw = role['uids'];
    if (raw is! List) return const [];
    return raw.map((e) => e.toString()).where((id) => id.isNotEmpty).toList();
  }

  /// True when [a] and [b] name the same people, ignoring order.
  static bool sameAssigneeIds(
      final Iterable<String> a, final Iterable<String> b) {
    final left = Set<String>.from(a);
    final right = Set<String>.from(b);
    return left.length == right.length && left.containsAll(right);
  }

  static bool isAssignedTo(final Map<String, dynamic> role, final String uid) {
    if (uid.isEmpty) return false;
    return uidsOf(role).contains(uid);
  }

  /// Ministries selected when the rota opens: the user's own active ministries,
  /// plus active ministries they head at [locationId].
  static Set<String> openingMinistryIds({
    required User user,
    required List<UserTag> allTags,
    required String locationId,
  }) {
    final ids = <String>{};
    final siteId = locationId.trim();
    for (final tag in allTags) {
      if (!tag.isActive) continue;
      if (user.tagIDs.contains(tag.id) ||
          (siteId.isNotEmpty &&
              tag.headsForLocation(siteId).contains(user.id))) {
        ids.add(tag.id);
      }
    }
    return ids;
  }

  /// A timed slot locks at its start. A slot with no start stays editable
  /// through [eventDate]'s calendar day.
  static bool roleHasStarted({
    required Map<String, dynamic> role,
    required DateTime? eventDate,
    required DateTime now,
  }) {
    final start = role['start'] as DateTime?;
    if (start != null) return !now.isBefore(start);
    if (eventDate == null) return false;
    final day = DateTime(eventDate.year, eventDate.month, eventDate.day);
    final today = DateTime(now.year, now.month, now.day);
    return day.isBefore(today);
  }

  /// Area admins may assign any tagged slot. A ministry head may assign a
  /// slot tagged with a ministry they head at [locationId]. Everyone else
  /// is read-only. A started slot is locked for both.
  static bool canAssignRole({
    required User actor,
    required Map<String, dynamic> role,
    required DateTime? eventDate,
    required String? locationId,
    required List<UserTag> allTags,
    required DateTime now,
  }) {
    if (roleHasStarted(role: role, eventDate: eventDate, now: now)) {
      return false;
    }
    final tagIds = EventProgram.tagIDsOf(role);
    if (tagIds.isEmpty) return false;
    if (actor.isAreaAdmin) return true;
    final siteId = locationId?.trim() ?? '';
    if (siteId.isEmpty) return false;
    for (final tagId in tagIds) {
      for (final tag in allTags) {
        if (tag.id != tagId) continue;
        if (tag.headsForLocation(siteId).contains(actor.id)) return true;
      }
    }
    return false;
  }

  static int unassignedRoleCount(final List<TeamRotaPost> posts) {
    var count = 0;
    for (final post in posts) {
      for (final role in post.roles) {
        if (uidsOf(role).isEmpty) count++;
      }
    }
    return count;
  }

  /// Keeps posts that still have an empty slot, and only those empty slots.
  static List<TeamRotaPost> postsNeedingPeople(final List<TeamRotaPost> posts) {
    final result = <TeamRotaPost>[];
    for (final post in posts) {
      final gaps = post.roles.where((role) => uidsOf(role).isEmpty).toList();
      if (gaps.isEmpty) continue;
      result.add(TeamRotaPost(head: post.head, roles: gaps));
    }
    return result;
  }

  static bool headMatchesLocation({
    required EventHead head,
    required String locationFilter,
  }) {
    if (head.isPeriodParent) return false;
    return VolunteerLocations.postLocationMatchesFilter(
      postLocation: head.location,
      locationFilter: locationFilter,
    );
  }

  /// True when the role is owned by any of [selectedTagIDs].
  ///
  /// An empty [selectedTagIDs] matches every tagged role (no ministry filter).
  /// Roles with no ministry tags are always omitted.
  static bool roleMatchesTeamTags({
    required Map<String, dynamic> role,
    required Set<String> selectedTagIDs,
  }) {
    final tags = EventProgram.tagIDsOf(role);
    if (tags.isEmpty) return false;
    if (selectedTagIDs.isEmpty) return true;
    return tags.any(selectedTagIDs.contains);
  }

  static List<TeamRotaPost> matchingPosts({
    required List<({EventHead head, EventProgram program})> posts,
    required Set<String> selectedTagIDs,
    required String locationFilter,
  }) {
    final result = <TeamRotaPost>[];
    for (final post in posts) {
      if (!headMatchesLocation(
        head: post.head,
        locationFilter: locationFilter,
      )) {
        continue;
      }
      final roles = post.program.roles
          .where((role) => roleMatchesTeamTags(
                role: role,
                selectedTagIDs: selectedTagIDs,
              ))
          .toList()
        ..sort(_compareRoleStart);
      if (roles.isEmpty) continue;
      result.add(TeamRotaPost(head: post.head, roles: roles));
    }

    result.sort((a, b) {
      final aDate = a.head.eventDate;
      final bDate = b.head.eventDate;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      final byDate = aDate.compareTo(bDate);
      if (byDate != 0) return byDate;
      return a.head.title.toLowerCase().compareTo(b.head.title.toLowerCase());
    });
    return result;
  }

  static List<TeamRotaMonthGroup> groupByMonth(final List<TeamRotaPost> posts) {
    final groups = <String, List<TeamRotaPost>>{};
    final order = <String>[];
    for (final post in posts) {
      final date = post.head.eventDate;
      if (date == null) continue;
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      if (!groups.containsKey(key)) {
        order.add(key);
        groups[key] = [];
      }
      groups[key]!.add(post);
    }
    return [
      for (final key in order)
        TeamRotaMonthGroup(
          year: int.parse(key.substring(0, 4)),
          month: int.parse(key.substring(5)),
          posts: groups[key]!,
        ),
    ];
  }

  static int _compareRoleStart(
    final Map<String, dynamic> a,
    final Map<String, dynamic> b,
  ) {
    final aStart = a['start'] as DateTime?;
    final bStart = b['start'] as DateTime?;
    if (aStart == null && bStart == null) return 0;
    if (aStart == null) return 1;
    if (bStart == null) return -1;
    return aStart.compareTo(bStart);
  }
}
