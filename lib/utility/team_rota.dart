import '../models/event/event_head.dart';
import '../models/event/event_program.dart';
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
/// assignee's personal tags. Untagged roles are omitted. Empty `uids` still
/// belong to the team.
class TeamRotaQuery {
  TeamRotaQuery._();

  static const int defaultHorizonMonths = 3;

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
  static bool roleMatchesTeamTags({
    required Map<String, dynamic> role,
    required Set<String> selectedTagIDs,
  }) {
    if (selectedTagIDs.isEmpty) return false;
    final tags = EventProgram.tagIDsOf(role);
    if (tags.isEmpty) return false;
    return tags.any(selectedTagIDs.contains);
  }

  static List<TeamRotaPost> matchingPosts({
    required List<({EventHead head, EventProgram program})> posts,
    required Set<String> selectedTagIDs,
    required String locationFilter,
  }) {
    if (selectedTagIDs.isEmpty) return const [];

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
