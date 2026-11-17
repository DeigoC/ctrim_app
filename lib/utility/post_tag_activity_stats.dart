import '../models/event/event_head.dart';
import '../models/event/lead_speaker.dart';
import '../models/user_location.dart';
import 'catalog/volunteer_locations.dart';

/// Past-window totals for one post tag, or one location of that tag.
class PostTagTotals {
  const PostTagTotals({
    required this.eventCount,
    required this.attendanceTotal,
    required this.interestedTotal,
  });

  final int eventCount;
  final int attendanceTotal;
  final int interestedTotal;

  static const empty = PostTagTotals(
    eventCount: 0,
    attendanceTotal: 0,
    interestedTotal: 0,
  );

  /// Attendance divided by events, including posts with none recorded.
  /// Null when there are no events.
  double? get averageAttendance =>
      eventCount == 0 ? null : attendanceTotal / eventCount;
}

/// One church location's dated posts for a single post tag.
class PostTagLocationRow {
  const PostTagLocationRow({
    required this.locationName,
    required this.past,
    required this.upcomingEventCount,
  });

  final String locationName;

  /// Already held, before local today.
  final PostTagTotals past;

  /// Today through the next three weeks. Not included in [past].
  final int upcomingEventCount;
}

/// A person who spoke on a past post with this tag.
class PostTagSpeaker {
  const PostTagSpeaker({
    required this.uid,
    required this.storedName,
    required this.imgSrc,
    required this.appearanceCount,
  });

  final String uid;
  final String? storedName;
  final String? imgSrc;
  final int appearanceCount;
}

/// Dated posts for one tag, split into already held and still ahead.
class PostTagActivitySnapshot {
  const PostTagActivitySnapshot({
    required this.pastHeads,
    required this.upcomingHeads,
    required this.locations,
    required this.past,
    required this.speakers,
  });

  /// Newest [EventHead.eventDate] first. Before local today.
  final List<EventHead> pastHeads;

  /// Soonest [EventHead.eventDate] first. Today through the lookahead.
  final List<EventHead> upcomingHeads;

  /// Every location with a matching post. Ignores the location filter.
  final List<PostTagLocationRow> locations;

  /// Past totals for the selected location, or every location when unset.
  final PostTagTotals past;

  /// Speakers on [pastHeads], most recent appearance first.
  final List<PostTagSpeaker> speakers;

  static const empty = PostTagActivitySnapshot(
    pastHeads: <EventHead>[],
    upcomingHeads: <EventHead>[],
    locations: <PostTagLocationRow>[],
    past: PostTagTotals.empty,
    speakers: <PostTagSpeaker>[],
  );
}

/// Event count and attendance for one post tag, grouped by church location.
///
/// A post counts when it carries the tag, has [EventHead.eventDate] inside
/// [rangeStartInclusive] .. [rangeEndExclusive], and is not a period parent.
/// Posts before local today are the progress window. Today through the end
/// of the range is upcoming and is not added into attendance or the average.
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

  /// Local midnight today. Posts before this are already held.
  static DateTime pastRangeEndExclusive(final DateTime now) => dayStart(now);

  /// Local midnight 21 days after [now], exclusive, so the next three weeks
  /// are included. Today is inside this end and counts as upcoming.
  static DateTime rangeEndExclusive(final DateTime now) =>
      dayStart(now).add(const Duration(days: lookaheadDays));

  /// [locationName] limits the lists, totals, and speakers. Location rows
  /// stay complete so the page can still switch site. An unknown name is
  /// treated as every location. `Belfast (Online)` is grouped with Belfast.
  static PostTagActivitySnapshot compute({
    required String tagId,
    required List<EventHead> heads,
    required List<UserLocation> locations,
    DateTime? now,
    String? locationName,
  }) {
    final id = tagId.trim();
    if (id.isEmpty) return PostTagActivitySnapshot.empty;

    final clock = now ?? DateTime.now();
    final start = rangeStartInclusive(clock);
    final pastEnd = pastRangeEndExclusive(clock);
    final end = rangeEndExclusive(clock);
    final pastAll = <EventHead>[];
    final upcomingAll = <EventHead>[];
    final buckets = <String, _LocationBucket>{};

    for (final head in heads) {
      if (!head.hasTag(id) || head.isPeriodParent) continue;
      final date = head.eventDate;
      if (date == null) continue;
      if (date.isBefore(start) || !date.isBefore(end)) continue;
      final name = VolunteerLocations.normalizePostLocation(head.location);
      if (name.isEmpty) continue;
      final bucket = buckets.putIfAbsent(name, _LocationBucket.new);
      if (date.isBefore(pastEnd)) {
        pastAll.add(head);
        bucket
          ..pastEvents += 1
          ..pastAttendance += head.attendeeCount
          ..pastInterested += head.interestedCount;
      } else {
        upcomingAll.add(head);
        bucket.upcoming += 1;
      }
    }

    final rows = _locationRows(buckets, locations);
    final known = rows
        .map((row) => row.locationName)
        .toSet()
        .contains(locationName?.trim());
    final filter = known ? locationName!.trim() : '';

    bool inScope(final EventHead head) {
      if (filter.isEmpty) return true;
      return VolunteerLocations.normalizePostLocation(head.location) == filter;
    }

    final pastHeads = pastAll.where(inScope).toList()
      ..sort((a, b) => b.eventDate!.compareTo(a.eventDate!));
    final upcomingHeads = upcomingAll.where(inScope).toList()
      ..sort((a, b) => a.eventDate!.compareTo(b.eventDate!));

    return PostTagActivitySnapshot(
      pastHeads: pastHeads,
      upcomingHeads: upcomingHeads,
      locations: rows,
      past: _totals(pastHeads),
      speakers: _speakers(pastHeads),
    );
  }

  static List<PostTagLocationRow> _locationRows(
    final Map<String, _LocationBucket> buckets,
    final List<UserLocation> locations,
  ) {
    final order = <String, int>{};
    for (final location in locations) {
      final name = location.name.trim();
      if (name.isEmpty) continue;
      order.putIfAbsent(name, () => location.displayOrder);
    }

    final rows = <PostTagLocationRow>[
      for (final entry in buckets.entries)
        PostTagLocationRow(
          locationName: entry.key,
          past: PostTagTotals(
            eventCount: entry.value.pastEvents,
            attendanceTotal: entry.value.pastAttendance,
            interestedTotal: entry.value.pastInterested,
          ),
          upcomingEventCount: entry.value.upcoming,
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

  static PostTagTotals _totals(final List<EventHead> heads) {
    var attendance = 0;
    var interested = 0;
    for (final head in heads) {
      attendance += head.attendeeCount;
      interested += head.interestedCount;
    }
    return PostTagTotals(
      eventCount: heads.length,
      attendanceTotal: attendance,
      interestedTotal: interested,
    );
  }

  /// First time a speaker appears wins the stored name and photo, because
  /// [heads] is newest first.
  static List<PostTagSpeaker> _speakers(final List<EventHead> heads) {
    final order = <String>[];
    final counts = <String, int>{};
    final snapshots = <String, LeadSpeakerSnapshot>{};
    for (final head in heads) {
      for (final speaker in head.leadSpeakers) {
        final uid = speaker.uid.trim();
        if (uid.isEmpty) continue;
        final seen = counts[uid];
        if (seen == null) {
          order.add(uid);
          counts[uid] = 1;
          snapshots[uid] = speaker;
        } else {
          counts[uid] = seen + 1;
        }
      }
    }
    return [
      for (final uid in order)
        PostTagSpeaker(
          uid: uid,
          storedName: snapshots[uid]!.name,
          imgSrc: snapshots[uid]!.imgSrc,
          appearanceCount: counts[uid]!,
        ),
    ];
  }
}

class _LocationBucket {
  int pastEvents = 0;
  int pastAttendance = 0;
  int pastInterested = 0;
  int upcoming = 0;
}
