import '../models/cell_group.dart';
import '../models/event/event_head.dart';
import '../models/user.dart';
import 'volunteer_locations.dart';

/// Rolling window for church-hub bulletin activity.
class ChurchLocationWindows {
  /// Inclusive lookback in days before local midnight today (today still counts).
  static const int pastDays = 90;

  const ChurchLocationWindows._();
}

/// Snapshot of activity for one church location (counts + lists for the hub).
///
/// Posts come from a dedicated [EventDate] range query — not the bulletin
/// session heads. Cell groups and people are filtered from [AppContext] lists.
class ChurchLocationStats {
  const ChurchLocationStats({
    required this.postCount,
    required this.cellGroupCount,
    required this.peopleCount,
    required this.posts,
    required this.cellGroups,
  });

  final int postCount;
  final int cellGroupCount;
  final int peopleCount;

  /// Location-matched posts in the window, newest [EventHead.eventDate] first.
  /// Period-parent series docs are excluded (same as the bulletin).
  final List<EventHead> posts;

  /// Non-archived cell groups at this location.
  final List<CellGroup> cellGroups;

  static ChurchLocationStats empty() => const ChurchLocationStats(
        postCount: 0,
        cellGroupCount: 0,
        peopleCount: 0,
        posts: <EventHead>[],
        cellGroups: <CellGroup>[],
      );

  static DateTime dayStart(final DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Inclusive start of the 90-day lookback (local midnight).
  static DateTime queryRangeStart(final DateTime now) => dayStart(now)
      .subtract(const Duration(days: ChurchLocationWindows.pastDays));

  /// Exclusive end — local midnight tomorrow, so all of today is included.
  static DateTime queryRangeEndExclusive(final DateTime now) =>
      dayStart(now).add(const Duration(days: 1));

  factory ChurchLocationStats.compute({
    required String location,
    required List<EventHead> heads,
    required List<CellGroup> groups,
    required List<User> users,
    DateTime? now,
  }) {
    final name = location.trim();
    if (name.isEmpty) return ChurchLocationStats.empty();

    final DateTime clock = now ?? DateTime.now();
    final DateTime start = queryRangeStart(clock);
    final DateTime end = queryRangeEndExclusive(clock);

    final matchedPosts = <EventHead>[];
    for (final head in heads) {
      if (head.isPeriodParent) continue;
      final eventDate = head.eventDate;
      if (eventDate == null) continue;
      if (eventDate.isBefore(start) || !eventDate.isBefore(end)) continue;
      if (!VolunteerLocations.postLocationMatchesFilter(
        postLocation: head.location,
        locationFilter: name,
      )) {
        continue;
      }
      matchedPosts.add(head);
    }
    matchedPosts.sort((a, b) {
      final aDate = a.eventDate!;
      final bDate = b.eventDate!;
      return bDate.compareTo(aDate);
    });

    final matchedGroups = <CellGroup>[];
    for (final group in groups) {
      if (group.isArchived) continue;
      if (!VolunteerLocations.postLocationMatchesFilter(
        postLocation: group.location,
        locationFilter: name,
      )) {
        continue;
      }
      matchedGroups.add(group);
    }

    var people = 0;
    for (final user in users) {
      if (user.isPlaceholder) continue;
      if (!VolunteerLocations.postLocationMatchesFilter(
        postLocation: user.location,
        locationFilter: name,
      )) {
        continue;
      }
      people++;
    }

    return ChurchLocationStats(
      postCount: matchedPosts.length,
      cellGroupCount: matchedGroups.length,
      peopleCount: people,
      posts: List<EventHead>.unmodifiable(matchedPosts),
      cellGroups: List<CellGroup>.unmodifiable(matchedGroups),
    );
  }
}
