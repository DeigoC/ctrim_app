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
  });

  final int groupCount;

  /// Sum of each group's [CellGroup.memberCount]. Someone in two groups
  /// is counted twice.
  final int membersListed;

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

  /// Location-matched posts in the window, newest first. Same list the hub
  /// chart uses.
  final List<EventHead> posts;

  bool get isEmpty => postCount == 0;

  static const ChurchLocationPostsSection empty = ChurchLocationPostsSection(
    postCount: 0,
    cellGroupMeetingCount: 0,
    otherPostCount: 0,
    attendanceTotal: 0,
    averageAttendance: null,
    interestedTotal: 0,
    tags: <ChurchLocationCountRow>[],
    posts: <EventHead>[],
  );
}

/// Breakdown of one church location for the statistics page.
///
/// People, groups, and posts use the same location match as
/// [ChurchLocationStats]. No extra queries.
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
    DateTime? now,
  }) {
    final name = location.trim();
    if (name.isEmpty) return ChurchLocationReport.empty;

    final stats = ChurchLocationStats.compute(
      location: name,
      heads: heads,
      groups: groups,
      users: users,
      now: now,
    );

    return ChurchLocationReport(
      people: _people(
        location: name,
        users: users,
        ministries: ministries,
        viewerIsGuest: viewerIsGuest,
      ),
      cellGroups: _groups(stats.cellGroups),
      posts: _posts(posts: stats.posts, postTags: postTags),
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

  static ChurchLocationGroupsSection _groups(final List<CellGroup> groups) {
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
    );
  }

  static ChurchLocationPostsSection _posts({
    required List<EventHead> posts,
    required List<PostTag> postTags,
  }) {
    if (posts.isEmpty) return ChurchLocationPostsSection.empty;

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
