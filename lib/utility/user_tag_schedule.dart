import '../models/event/event_head.dart';
import '../models/event/event_program.dart';
import 'team_rota.dart';

/// Past and upcoming programme slots for one team tag at one church location.
///
/// The join is the same as [TeamRotaQuery]: role `tagIDs`, not the assignee's
/// personal tags. The page fetches heads in [rangeStartInclusive] ..
/// [rangeEndExclusive] and does not store them on the session bulletin list.
class UserTagScheduleQuery {
  UserTagScheduleQuery._();

  static const int horizonMonths = TeamRotaQuery.defaultHorizonMonths;

  /// Start of the day three months before [now].
  static DateTime rangeStartInclusive(final DateTime now) {
    final today = TeamRotaQuery.rangeStart(now);
    return DateTime(today.year, today.month - horizonMonths, today.day);
  }

  /// Start of the day three months after [now], exclusive.
  static DateTime rangeEndExclusive(final DateTime now) {
    return TeamRotaQuery.rangeEndExclusive(now, months: horizonMonths);
  }

  /// Splits matching posts at the start of [now]'s calendar day.
  ///
  /// Upcoming is soonest first. Past is newest first. When [guestsOnly] is
  /// set, roles with `for_guests` other than true are dropped, and a post
  /// with no remaining roles is omitted.
  static ({List<TeamRotaPost> upcoming, List<TeamRotaPost> past}) split({
    required List<({EventHead head, EventProgram program})> posts,
    required String tagId,
    required String locationName,
    required DateTime now,
    bool guestsOnly = false,
  }) {
    final today = TeamRotaQuery.rangeStart(now);
    final matched = _visiblePosts(
      posts: TeamRotaQuery.matchingPosts(
        posts: posts,
        selectedTagIDs: {tagId},
        locationFilter: locationName,
      ),
      guestsOnly: guestsOnly,
    );

    final upcoming = <TeamRotaPost>[];
    final past = <TeamRotaPost>[];
    for (final post in matched) {
      final date = post.head.eventDate;
      if (date == null) continue;
      if (date.isBefore(today)) {
        past.add(post);
      } else {
        upcoming.add(post);
      }
    }

    past.sort((a, b) {
      final byDate = b.head.eventDate!.compareTo(a.head.eventDate!);
      if (byDate != 0) return byDate;
      return b.head.title.toLowerCase().compareTo(a.head.title.toLowerCase());
    });

    return (upcoming: upcoming, past: past);
  }

  static List<TeamRotaPost> _visiblePosts({
    required List<TeamRotaPost> posts,
    required bool guestsOnly,
  }) {
    if (!guestsOnly) return posts;
    final visible = <TeamRotaPost>[];
    for (final post in posts) {
      final roles =
          post.roles.where((role) => role['for_guests'] == true).toList();
      if (roles.isEmpty) continue;
      visible.add(TeamRotaPost(head: post.head, roles: roles));
    }
    return visible;
  }
}
