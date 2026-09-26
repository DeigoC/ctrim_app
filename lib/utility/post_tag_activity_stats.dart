import '../models/event/event_head.dart';
import '../models/user_location.dart';
import 'catalog/volunteer_locations.dart';

/// One church location's dated posts for a single post tag.
class PostTagLocationRow {
  const PostTagLocationRow({
    required this.locationName,
    required this.eventCount,
    required this.attendanceTotal,
  });

  final String locationName;
  final int eventCount;
  final int attendanceTotal;
}

/// Event count and attendance for one post tag, grouped by church location.
///
/// A post counts when it carries the tag, has [EventHead.eventDate] inside
/// [rangeStartInclusive] .. [rangeEndExclusive], and is not a period parent.
/// Attendance is the denormalized [EventHead.attendeeCount].
class PostTagActivityStats {
  const PostTagActivityStats._();

  static const int lookbackMonths = 2;
  static const int lookaheadDays = 21;

  static DateTime dayStart(final DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Local midnight two calendar months before [now].
  static DateTime rangeStartInclusive(final DateTime now) {
    final today = dayStart(now);
    return DateTime(today.year, today.month - lookbackMonths, today.day);
  }

  /// Local midnight 21 days after [now], exclusive, so the next three weeks
  /// are included.
  static DateTime rangeEndExclusive(final DateTime now) =>
      dayStart(now).add(const Duration(days: lookaheadDays));

  /// Locations with at least one matching event. Catalogue [locations] set
  /// the order; names that are not in the catalogue follow, A–Z.
  ///
  /// `Belfast (Online)` is grouped with Belfast.
  static List<PostTagLocationRow> byLocation({
    required String tagId,
    required List<EventHead> heads,
    required List<UserLocation> locations,
    DateTime? now,
  }) {
    final id = tagId.trim();
    if (id.isEmpty) return const [];

    final clock = now ?? DateTime.now();
    final start = rangeStartInclusive(clock);
    final end = rangeEndExclusive(clock);
    final totals = <String, ({int events, int attendance})>{};

    for (final head in heads) {
      if (!head.hasTag(id) || head.isPeriodParent) continue;
      final date = head.eventDate;
      if (date == null) continue;
      if (date.isBefore(start) || !date.isBefore(end)) continue;
      final name = VolunteerLocations.normalizePostLocation(head.location);
      if (name.isEmpty) continue;
      final current = totals[name];
      totals[name] = (
        events: (current?.events ?? 0) + 1,
        attendance: (current?.attendance ?? 0) + head.attendeeCount,
      );
    }

    final order = <String, int>{};
    for (final location in locations) {
      final name = location.name.trim();
      if (name.isEmpty) continue;
      order.putIfAbsent(name, () => location.displayOrder);
    }

    final rows = <PostTagLocationRow>[
      for (final entry in totals.entries)
        PostTagLocationRow(
          locationName: entry.key,
          eventCount: entry.value.events,
          attendanceTotal: entry.value.attendance,
        ),
    ];
    rows.sort((a, b) {
      final aOrder = order[a.locationName];
      final bOrder = order[b.locationName];
      if (aOrder != null && bOrder != null && aOrder != bOrder) {
        return aOrder.compareTo(bOrder);
      }
      if (aOrder != null && bOrder == null) return -1;
      if (aOrder == null && bOrder != null) return 1;
      return a.locationName
          .toLowerCase()
          .compareTo(b.locationName.toLowerCase());
    });
    return rows;
  }
}
