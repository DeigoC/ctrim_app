import '../models/cell_group.dart';
import '../models/event/event_head.dart';
import '../models/post_tag.dart';
import '../models/user.dart';
import '../models/user_tag.dart';
import 'catalog/volunteer_locations.dart';
import 'church_location_stats.dart';

/// One labelled count on the location statistics page.
class ChurchLocationCountRow {
  const ChurchLocationCountRow({
    required this.id,
    required this.name,
    required this.count,
    this.colorHex,
  });

  final String id;
  final String name;
  final int count;
  final String? colorHex;
}

/// People at one church location, with ministry counts for the viewer.
class ChurchLocationPeopleSection {
  const ChurchLocationPeopleSection({
    required this.profileCount,
    required this.inMinistryCount,
    required this.notInMinistryCount,
    required this.leaderCount,
    required this.ministries,
  });

  final int profileCount;
  final int inMinistryCount;
  final int notInMinistryCount;
  final int leaderCount;

  /// Active ministries with at least one person here, largest first.
  ///
  /// Guests omit ministries hidden from guests. A person in two ministries
  /// is counted in each row, and once in [inMinistryCount].
  final List<ChurchLocationCountRow> ministries;

  bool get isEmpty => profileCount == 0;

  static const ChurchLocationPeopleSection empty = ChurchLocationPeopleSection(
    profileCount: 0,
    inMinistryCount: 0,
    notInMinistryCount: 0,
    leaderCount: 0,
    ministries: <ChurchLocationCountRow>[],
  );
}

/// Cell groups at one church location.
class ChurchLocationGroupsSection {
  const ChurchLocationGroupsSection({
    required this.groupCount,
    required this.membersListed,
    required this.averageSize,
    required this.groups,
    this.uniquePeople,
  });

  final int groupCount;

  /// Sum of each group's [CellGroup.memberCount]. Someone in two groups
  /// is counted twice.
  final int membersListed;

  /// Distinct linked people on the rosters of these groups. Someone in two
  /// groups counts once. Null when rosters were not read (guests).
  final int? uniquePeople;

  /// [membersListed] / [groupCount], or null when there are no groups.
  final double? averageSize;

  /// Largest [CellGroup.memberCount] first. [ChurchLocationCountRow.id] is
  /// the cell group id.
  final List<ChurchLocationCountRow> groups;

  bool get isEmpty => groupCount == 0;

  static const ChurchLocationGroupsSection empty = ChurchLocationGroupsSection(
    groupCount: 0,
    membersListed: 0,
    averageSize: null,
    groups: <ChurchLocationCountRow>[],
  );
}

/// Posts coming up at one church location.
///
/// Same window as cell-group activity: today and the next 6 days. Not
/// included in [ChurchLocationPostsSection] attendance.
class ChurchLocationUpcomingPosts {
  const ChurchLocationUpcomingPosts({
    required this.postCount,
    required this.cellGroupMeetingCount,
    required this.otherPostCount,
  });

  final int postCount;
  final int cellGroupMeetingCount;
  final int otherPostCount;

  bool get isEmpty => postCount == 0;

  static const ChurchLocationUpcomingPosts empty = ChurchLocationUpcomingPosts(
    postCount: 0,
    cellGroupMeetingCount: 0,
    otherPostCount: 0,
  );
}

/// Bulletin posts at one church location in the hub's 90-day window.
class ChurchLocationPostsSection {
  const ChurchLocationPostsSection({
    required this.postCount,
    required this.cellGroupMeetingCount,
    required this.otherPostCount,
    required this.attendanceTotal,
    required this.averageAttendance,
    required this.interestedTotal,
    required this.tags,
    required this.posts,
    required this.upcoming,
  });

  final int postCount;
  final int cellGroupMeetingCount;
  final int otherPostCount;
  final int attendanceTotal;

  /// [attendanceTotal] / [postCount], including posts with no attendance
  /// recorded. Null when there are no posts.
  final double? averageAttendance;

  final int interestedTotal;

  /// Active post tags with at least one post, largest first. A trailing row
  /// with [ChurchLocationReport.untaggedPostId] covers posts with no active tag.
  final List<ChurchLocationCountRow> tags;

  /// Location-matched posts in the 90-day window, newest first. Same list
  /// the hub chart uses. Upcoming posts are not included.
  final List<EventHead> posts;

  /// Location-matched posts in the cell-group upcoming week.
  final ChurchLocationUpcomingPosts upcoming;

  bool get isEmpty => postCount == 0 && upcoming.isEmpty;

  static const ChurchLocationPostsSection empty = ChurchLocationPostsSection(
    postCount: 0,
    cellGroupMeetingCount: 0,
    otherPostCount: 0,
    attendanceTotal: 0,
    averageAttendance: null,
    interestedTotal: 0,
    tags: <ChurchLocationCountRow>[],
    posts: <EventHead>[],
    upcoming: ChurchLocationUpcomingPosts.empty,
  );
}

/// Breakdown of one church location for the statistics page.
///
/// People, groups, and the 90-day posts use the same location match as
/// [ChurchLocationStats]. Upcoming posts are a separate date window and
/// stay out of attendance. Distinct cell-group people come from roster
/// ids supplied by the caller; this type does not read Firestore.
class ChurchLocationReport {
  const ChurchLocationReport({
    required this.people,
    required this.cellGroups,
    required this.posts,
  });

  /// Row id for posts that have no active post tag. The page supplies the label.
  static const String untaggedPostId = '__untagged__';

  final ChurchLocationPeopleSection people;
  final ChurchLocationGroupsSection cellGroups;
  final ChurchLocationPostsSection posts;

  static const ChurchLocationReport empty = ChurchLocationReport(
    people: ChurchLocationPeopleSection.empty,
    cellGroups: ChurchLocationGroupsSection.empty,
    posts: ChurchLocationPostsSection.empty,
  );

  factory ChurchLocationReport.compute({
    required String location,
    required List<User> users,
    required List<CellGroup> groups,
    required List<EventHead> heads,
    required List<UserTag> ministries,
    required List<PostTag> postTags,
    required bool viewerIsGuest,
    List<EventHead> upcomingHeads = const [],
    Iterable<Iterable<String>>? rosterUserIdsByGroup,
    DateTime? now,
  }) {
    final name = location.trim();
    if (name.isEmpty) return ChurchLocationReport.empty;

    final DateTime clock = now ?? DateTime.now();
    final stats = ChurchLocationStats.compute(
      location: name,
      heads: heads,
      groups: groups,
      users: users,
      now: clock,
    );

    return ChurchLocationReport(
      people: _people(
        location: name,
        users: users,
        ministries: ministries,
        viewerIsGuest: viewerIsGuest,
      ),
      cellGroups: _groups(
        stats.cellGroups,
        rosterUserIdsByGroup: rosterUserIdsByGroup,
      ),
      posts: _posts(
        posts: stats.posts,
        postTags: postTags,
        upcoming: _upcoming(
          location: name,
          heads: upcomingHeads,
          now: clock,
        ),
      ),
    );
  }

  static ChurchLocationPeopleSection _people({
    required String location,
    required List<User> users,
    required List<UserTag> ministries,
    required bool viewerIsGuest,
  }) {
    final visible = <UserTag>[];
    for (final tag in ministries) {
      if (!tag.isActive) continue;
      if (viewerIsGuest && !tag.visibleToGuests) continue;
      visible.add(tag);
    }
    final visibleIds = <String>{for (final tag in visible) tag.id};
    final counts = <String, int>{for (final tag in visible) tag.id: 0};

    var profiles = 0;
    var inMinistry = 0;
    var leaders = 0;
    for (final user in users) {
      if (!_personAtLocation(user, location)) continue;
      profiles++;
      if (user.isLeader) leaders++;
      var matched = false;
      final seen = <String>{};
      for (final id in user.tagIDs) {
        if (!visibleIds.contains(id) || !seen.add(id)) continue;
        counts[id] = counts[id]! + 1;
        matched = true;
      }
      if (matched) inMinistry++;
    }

    final rows = <ChurchLocationCountRow>[];
    for (final tag in visible) {
      final count = counts[tag.id] ?? 0;
      if (count == 0) continue;
      rows.add(ChurchLocationCountRow(
        id: tag.id,
        name: tag.name,
        count: count,
        colorHex: tag.color,
      ));
    }
    rows.sort(_byCountThenName);

    return ChurchLocationPeopleSection(
      profileCount: profiles,
      inMinistryCount: inMinistry,
      notInMinistryCount: profiles - inMinistry,
      leaderCount: leaders,
      ministries: List<ChurchLocationCountRow>.unmodifiable(rows),
    );
  }

  /// Same people filter as [ChurchLocationStats.compute].
  static bool _personAtLocation(final User user, final String location) {
    if (user.isPlaceholder) return false;
    if (user.isProfileInactive) return false;
    return VolunteerLocations.postLocationMatchesFilter(
      postLocation: user.location,
      locationFilter: location,
    );
  }

  static ChurchLocationGroupsSection _groups(
    final List<CellGroup> groups, {
    Iterable<Iterable<String>>? rosterUserIdsByGroup,
  }) {
    if (groups.isEmpty) return ChurchLocationGroupsSection.empty;

    var members = 0;
    final rows = <ChurchLocationCountRow>[];
    for (final group in groups) {
      members += group.memberCount;
      rows.add(ChurchLocationCountRow(
        id: group.id,
        name: group.name,
        count: group.memberCount,
      ));
    }
    rows.sort(_byCountThenName);

    return ChurchLocationGroupsSection(
      groupCount: groups.length,
      membersListed: members,
      averageSize: members / groups.length,
      groups: List<ChurchLocationCountRow>.unmodifiable(rows),
      uniquePeople: rosterUserIdsByGroup == null
          ? null
          : _distinctRosterPeople(rosterUserIdsByGroup),
    );
  }

  /// Blank ids are ignored. The same id in two groups counts once.
  static int _distinctRosterPeople(Iterable<Iterable<String>> idsByGroup) {
    final ids = <String>{};
    for (final group in idsByGroup) {
      for (final id in group) {
        final trimmed = id.trim();
        if (trimmed.isNotEmpty) ids.add(trimmed);
      }
    }
    return ids.length;
  }

  static ChurchLocationUpcomingPosts _upcoming({
    required String location,
    required List<EventHead> heads,
    required DateTime now,
  }) {
    final start = ChurchLocationStats.upcomingQueryRangeStart(now);
    final end = ChurchLocationStats.upcomingQueryRangeEndExclusive(now);
    var count = 0;
    var meetings = 0;
    for (final post in heads) {
      if (post.isPeriodParent) continue;
      final eventDate = post.eventDate;
      if (eventDate == null) continue;
      if (eventDate.isBefore(start) || !eventDate.isBefore(end)) continue;
      if (!VolunteerLocations.postLocationMatchesFilter(
        postLocation: post.location,
        locationFilter: location,
      )) {
        continue;
      }
      count++;
      if (post.cellGroupIDs.isNotEmpty) meetings++;
    }
    if (count == 0) return ChurchLocationUpcomingPosts.empty;
    return ChurchLocationUpcomingPosts(
      postCount: count,
      cellGroupMeetingCount: meetings,
      otherPostCount: count - meetings,
    );
  }

  static ChurchLocationPostsSection _posts({
    required List<EventHead> posts,
    required List<PostTag> postTags,
    required ChurchLocationUpcomingPosts upcoming,
  }) {
    if (posts.isEmpty) {
      return ChurchLocationPostsSection(
        postCount: 0,
        cellGroupMeetingCount: 0,
        otherPostCount: 0,
        attendanceTotal: 0,
        averageAttendance: null,
        interestedTotal: 0,
        tags: const <ChurchLocationCountRow>[],
        posts: const <EventHead>[],
        upcoming: upcoming,
      );
    }

    final active = <PostTag>[];
    for (final tag in postTags) {
      if (!tag.isActive) continue;
      active.add(tag);
    }
    final activeIds = <String>{for (final tag in active) tag.id};
    final counts = <String, int>{for (final tag in active) tag.id: 0};

    var meetings = 0;
    var attendance = 0;
    var interested = 0;
    var untagged = 0;
    for (final post in posts) {
      if (post.cellGroupIDs.isNotEmpty) meetings++;
      attendance += post.attendeeCount;
      interested += post.interestedCount;
      var matched = false;
      final seen = <String>{};
      for (final id in post.tagIDs) {
        if (!activeIds.contains(id) || !seen.add(id)) continue;
        counts[id] = counts[id]! + 1;
        matched = true;
      }
      if (!matched) untagged++;
    }

    final rows = <ChurchLocationCountRow>[];
    for (final tag in active) {
      final count = counts[tag.id] ?? 0;
      if (count == 0) continue;
      rows.add(ChurchLocationCountRow(
        id: tag.id,
        name: tag.name,
        count: count,
        colorHex: tag.color,
      ));
    }
    rows.sort(_byCountThenName);
    if (untagged > 0) {
      rows.add(ChurchLocationCountRow(
        id: untaggedPostId,
        name: '',
        count: untagged,
      ));
    }

    return ChurchLocationPostsSection(
      postCount: posts.length,
      cellGroupMeetingCount: meetings,
      otherPostCount: posts.length - meetings,
      attendanceTotal: attendance,
      averageAttendance: attendance / posts.length,
      interestedTotal: interested,
      tags: List<ChurchLocationCountRow>.unmodifiable(rows),
      posts: posts,
      upcoming: upcoming,
    );
  }

  static int _byCountThenName(
    final ChurchLocationCountRow a,
    final ChurchLocationCountRow b,
  ) {
    final byCount = b.count.compareTo(a.count);
    if (byCount != 0) return byCount;
    final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
    if (byName != 0) return byName;
    return a.id.compareTo(b.id);
  }
}
