import '../models/event/event_head.dart';
import 'catalog/post_tag_helpers.dart';
import 'catalog/volunteer_locations.dart';

/// How bulletin cards are ordered after filters apply.
enum BulletinSort {
  relevancy,
  eventDateSoonest,
  eventDateLatest;

  static BulletinSort fromStorage(final String? raw) {
    for (final value in values) {
      if (value.name == raw) return value;
    }
    return relevancy;
  }
}

/// Which dated posts the bulletin keeps (independent of [BulletinSort]).
enum BulletinTimeFilter {
  all,
  upcoming,
  past;

  static BulletinTimeFilter fromStorage(final String? raw) {
    for (final value in values) {
      if (value.name == raw) return value;
    }
    return all;
  }
}

/// Inputs for [BulletinListing.apply]. Construct outside `build` when possible.
class BulletinListingQuery {
  const BulletinListingQuery({
    this.sort = BulletinSort.relevancy,
    this.timeFilter = BulletinTimeFilter.all,
    this.bookmarksOnly = false,
    this.bookmarkedIds = const {},
    this.selectedTagIDs = const {},
    this.locationFilter = VolunteerLocations.all,
    this.excludePeriodParents = true,
    required this.now,
  });

  final BulletinSort sort;
  final BulletinTimeFilter timeFilter;
  final bool bookmarksOnly;
  final Set<String> bookmarkedIds;
  final Set<String> selectedTagIDs;
  final String locationFilter;
  final bool excludePeriodParents;
  final DateTime now;

  bool get hasActiveFilters =>
      timeFilter != BulletinTimeFilter.all ||
      bookmarksOnly ||
      selectedTagIDs.isNotEmpty ||
      locationFilter != VolunteerLocations.all;

  bool get showsNonDefaultBanner =>
      sort != BulletinSort.relevancy || hasActiveFilters;
}

/// Pure bulletin list pipeline: dedupe → filter → sort. Does not mutate [heads].
class BulletinListing {
  BulletinListing._();

  /// An event stays in Upcoming until this long after its start.
  static const Duration upcomingGrace = Duration(hours: 12);

  static List<EventHead> apply({
    required Iterable<EventHead> heads,
    required BulletinListingQuery query,
  }) {
    final unique = uniqueEventHeads(heads);
    final filtered =
        unique.where((head) => matchesFilters(head, query)).toList();
    return sortHeads(filtered, query.sort, query.now);
  }

  static List<EventHead> uniqueEventHeads(final Iterable<EventHead> heads) {
    final map = <String, EventHead>{};
    for (final head in heads) {
      map.putIfAbsent(head.id, () => head);
    }
    return map.values.toList();
  }

  static bool matchesFilters(
    final EventHead head,
    final BulletinListingQuery query,
  ) {
    if (query.excludePeriodParents && head.isPeriodParent) return false;
    if (query.bookmarksOnly && !query.bookmarkedIds.contains(head.id)) {
      return false;
    }
    if (!PostTagHelpers.headMatchesTagFilter(
      head: head,
      selectedTagIDs: query.selectedTagIDs,
    )) {
      return false;
    }
    if (!VolunteerLocations.postLocationMatchesFilter(
      postLocation: head.location,
      locationFilter: query.locationFilter,
    )) {
      return false;
    }
    switch (query.timeFilter) {
      case BulletinTimeFilter.all:
        return true;
      case BulletinTimeFilter.upcoming:
        return isUpcoming(head, query.now);
      case BulletinTimeFilter.past:
        return isPast(head, query.now);
    }
  }

  static bool isUpcoming(final EventHead head, final DateTime now) {
    final eventDate = head.eventDate;
    if (eventDate == null) return false;
    return !eventDate.add(upcomingGrace).isBefore(now);
  }

  static bool isPast(final EventHead head, final DateTime now) {
    final eventDate = head.eventDate;
    if (eventDate == null) return false;
    return eventDate.isBefore(now);
  }

  static bool isSameCalendarDay(final DateTime a, final DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static List<EventHead> sortHeads(
    final List<EventHead> heads,
    final BulletinSort sort,
    final DateTime now,
  ) {
    switch (sort) {
      case BulletinSort.relevancy:
        return _sortRelevancy(heads, now);
      case BulletinSort.eventDateSoonest:
        return List<EventHead>.from(heads)
          ..sort((a, b) => _compareEventDate(a, b, descending: false));
      case BulletinSort.eventDateLatest:
        return List<EventHead>.from(heads)
          ..sort((a, b) => _compareEventDate(a, b, descending: true));
    }
  }

  static int _compareEventDate(
    final EventHead a,
    final EventHead b, {
    required bool descending,
  }) {
    if (a.eventDate == null && b.eventDate == null) return 0;
    if (a.eventDate == null) return 1;
    if (b.eventDate == null) return -1;
    final cmp = a.eventDate!.compareTo(b.eventDate!);
    return descending ? -cmp : cmp;
  }

  /// Today (by calendar), then all later events by date, then the rest by last update.
  static List<EventHead> _sortRelevancy(
    final List<EventHead> heads,
    final DateTime now,
  ) {
    final today = <EventHead>[];
    final upcoming = <EventHead>[];
    final rest = <EventHead>[];
    for (final head in heads) {
      final eventDate = head.eventDate;
      if (eventDate != null && isSameCalendarDay(eventDate, now)) {
        today.add(head);
      } else if (eventDate != null && eventDate.isAfter(now)) {
        upcoming.add(head);
      } else {
        rest.add(head);
      }
    }
    today.sort((a, b) => a.eventDate!.compareTo(b.eventDate!));
    upcoming.sort((a, b) => a.eventDate!.compareTo(b.eventDate!));
    rest.sort((a, b) => b.recentDate.compareTo(a.recentDate));
    return [...today, ...upcoming, ...rest];
  }
}
