import '../firebase/db_managers/event_db_manager.dart';
import '../models/event/event_head.dart';
import '../models/event/event_program.dart';
import '../models/user.dart';
import '../models/user_location.dart';
import '../models/user_tag.dart';
import 'catalog/volunteer_locations.dart';
import 'team_rota.dart';

/// Personal home glance at Ministry Schedule.
///
/// The month list stays on the Ministry Schedule page. This snapshot is the
/// next few services for the ministries that page opens on.
class MinistrySchedulePreviewSnapshot {
  const MinistrySchedulePreviewSnapshot({
    required this.posts,
    required this.programs,
    required this.selectedTagIDs,
    required this.locationFilter,
  });

  final List<TeamRotaPost> posts;
  final Map<String, EventProgram> programs;
  final Set<String> selectedTagIDs;
  final String locationFilter;

  TeamRotaGap? get firstGap {
    final gaps = TeamRotaQuery.firstGaps(posts, limit: 1);
    if (gaps.isEmpty) return null;
    return gaps.first;
  }

  bool get hasOpenSlot => TeamRotaQuery.unassignedRoleCount(posts) > 0;
}

/// Which services the Personal card shows, and how it loads them.
abstract final class MinistrySchedulePreview {
  /// Rows on the card.
  static const int visiblePostCount = 3;

  /// Programme reads on Personal before stopping. Later posts stay on the
  /// full Ministry Schedule page.
  static const int programmeReadCap = 8;

  /// Soonest location-matching heads, capped at [cap].
  static List<EventHead> headsForProgrammeReads({
    required List<EventHead> heads,
    required String locationFilter,
    int cap = programmeReadCap,
  }) {
    final matched = <EventHead>[
      for (final head in heads)
        if (TeamRotaQuery.headMatchesLocation(
          head: head,
          locationFilter: locationFilter,
        ))
          head,
    ];
    matched.sort(_byDateThenTitle);
    if (matched.length <= cap) return matched;
    return matched.sublist(0, cap);
  }

  /// First [limit] posts. [posts] is already in date order.
  static List<TeamRotaPost> visiblePosts(
    List<TeamRotaPost> posts, {
    int limit = visiblePostCount,
  }) {
    if (posts.length <= limit) return posts;
    return posts.sublist(0, limit);
  }

  /// People on this post's ministry slots, first appearance first.
  static List<String> assigneeIds(TeamRotaPost post) {
    final ids = <String>[];
    final seen = <String>{};
    for (final role in post.roles) {
      for (final id in TeamRotaQuery.uidsOf(role)) {
        if (seen.add(id)) ids.add(id);
      }
    }
    return ids;
  }

  /// One post after its programme changes. Null when no ministry slot remains.
  static TeamRotaPost? singlePost({
    required EventHead head,
    required EventProgram program,
    required Set<String> selectedTagIDs,
    required String locationFilter,
  }) {
    final posts = TeamRotaQuery.matchingPosts(
      posts: [(head: head, program: program)],
      selectedTagIDs: selectedTagIDs,
      locationFilter: locationFilter,
    );
    if (posts.isEmpty) return null;
    return posts.single;
  }

  static Future<MinistrySchedulePreviewSnapshot> load({
    required User user,
    required List<UserTag> allTags,
    required List<UserLocation> locations,
    DateTime? now,
    EventHeadDBManager? headsDb,
    Future<EventProgram?> Function(String postId)? readProgram,
  }) async {
    final clock = now ?? DateTime.now();
    final locationFilter = VolunteerLocations.defaultFilterForUser(
      user.location,
      VolunteerLocations.assignableFrom(locations),
    );
    final locationId = VolunteerLocations.idForName(
      locations: locations,
      name: locationFilter,
    );
    final selectedTagIDs = TeamRotaQuery.openingMinistryIds(
      user: user,
      allTags: allTags,
      locationId: locationId ?? '',
    );
    final db = headsDb ?? EventHeadDBManager();
    final heads = await db.fetchHeadsWithEventDateInRange(
      startInclusive: TeamRotaQuery.rangeStart(clock),
      endExclusive: TeamRotaQuery.rangeEndExclusive(clock),
    );
    final candidates = headsForProgrammeReads(
      heads: heads,
      locationFilter: locationFilter,
    );
    final programs = <String, EventProgram>{};
    await Future.wait(candidates.map((head) async {
      final program = readProgram != null
          ? await readProgram(head.id)
          : await EventSupplementalDBManager(head.id).fetchProgramIfExists();
      if (program != null) programs[head.id] = program;
    }));
    final matching = TeamRotaQuery.matchingPosts(
      posts: [
        for (final head in candidates)
          if (programs.containsKey(head.id))
            (head: head, program: programs[head.id]!),
      ],
      selectedTagIDs: selectedTagIDs,
      locationFilter: locationFilter,
    );
    final posts = visiblePosts(matching);
    return MinistrySchedulePreviewSnapshot(
      posts: posts,
      programs: {
        for (final post in posts)
          if (programs.containsKey(post.head.id))
            post.head.id: programs[post.head.id]!,
      },
      selectedTagIDs: selectedTagIDs,
      locationFilter: locationFilter,
    );
  }

  static int _byDateThenTitle(EventHead a, EventHead b) {
    final aDate = a.eventDate;
    final bDate = b.eventDate;
    if (aDate == null && bDate == null) {
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    }
    if (aDate == null) return 1;
    if (bDate == null) return -1;
    final byDate = aDate.compareTo(bDate);
    if (byDate != 0) return byDate;
    return a.title.toLowerCase().compareTo(b.title.toLowerCase());
  }
}
