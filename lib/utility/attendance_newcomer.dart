import '../firebase/db_managers/event_db_manager.dart';
import '../models/event/event_attendance.dart';
import '../models/event/event_head.dart';

/// How familiar someone already is with this post's series.
enum AttendanceVisitMark {
  /// First check-in in the series.
  first,

  /// Second or third check-in, before they count as a regular.
  returning,
}

/// One earlier post and the attendance list saved on it.
class AttendanceSeriesPost {
  const AttendanceSeriesPost({
    required this.head,
    required this.attendance,
  });

  final EventHead head;
  final EventAttendance attendance;
}

/// Which earlier posts count for [AttendanceNewcomer].
class AttendanceSeriesScope {
  const AttendanceSeriesScope._(this.ids, this.usesCellGroups);

  const AttendanceSeriesScope.none() : this._(const [], false);

  const AttendanceSeriesScope.cellGroups(List<String> ids) : this._(ids, true);

  const AttendanceSeriesScope.tags(List<String> ids) : this._(ids, false);

  final List<String> ids;

  /// Cell-group links win over post tags.
  final bool usesCellGroups;

  bool get applies => ids.isNotEmpty;
}

/// First three attendance check-ins in one cell group, or one post tag.
///
/// A linked cell group is the series, even when the post also has tags.
/// With no cell group, each of the post's tags is counted and the highest
/// prior count wins, so an extra tag does not make a regular look new.
/// Free-text attendees have no person id and are never marked.
///
/// Marks stay off until the series already has [priorListsBeforeMarks]
/// earlier posts with someone on the attendance list.
abstract final class AttendanceNewcomer {
  /// Newest earlier posts read per cell group or tag.
  static const int lookbackPosts = 40;

  /// Visit 1 is [AttendanceVisitMark.first]; visits 2 and 3 are returning.
  static const int markedVisits = 3;

  /// Saved attendance lists required before any mark is shown.
  static const int priorListsBeforeMarks = 3;

  static AttendanceSeriesScope scopeFor(EventHead head) {
    if (head.eventDate == null) return const AttendanceSeriesScope.none();
    final groups = _ids(head.cellGroupIDs);
    if (groups.isNotEmpty) return AttendanceSeriesScope.cellGroups(groups);
    final tags = _ids(head.tagIDs);
    if (tags.isNotEmpty) return AttendanceSeriesScope.tags(tags);
    return const AttendanceSeriesScope.none();
  }

  /// Person id to mark, for people on [attendees]. Missing ids are regulars.
  static Map<String, AttendanceVisitMark> marksFor({
    required EventHead current,
    required Iterable<AttendeeEntry> attendees,
    required List<AttendanceSeriesPost> earlier,
  }) {
    final scope = scopeFor(current);
    if (!scope.applies) return const {};

    final userIds = <String>{
      for (final entry in attendees)
        if (entry.isUser && entry.userId != null && entry.userId!.isNotEmpty)
          entry.userId!,
    };
    if (userIds.isEmpty) return const {};

    final relevant = [
      for (final post in earlier)
        if (_isEarlierInScope(current, scope, post.head)) post,
    ];

    var savedLists = 0;
    for (final post in relevant) {
      if (post.attendance.attendeeCount > 0) savedLists++;
    }
    if (savedLists < priorListsBeforeMarks) return const {};

    final marks = <String, AttendanceVisitMark>{};
    for (final userId in userIds) {
      final prior = scope.usesCellGroups
          ? _postsWithUser(relevant, userId)
          : _bestTagCount(relevant, scope.ids, userId);
      final mark = _markForPrior(prior);
      if (mark != null) marks[userId] = mark;
    }
    return marks;
  }

  /// Earlier posts in [current]'s series, each with its attendance list.
  ///
  /// An empty list means there is nothing to compare (no date, no cell group
  /// and no tag). A failed read is left to the caller.
  static Future<List<AttendanceSeriesPost>> loadEarlier({
    required EventHead current,
    EventHeadDBManager? headManager,
    Future<EventAttendance> Function(String postId)? fetchAttendance,
  }) async {
    final scope = scopeFor(current);
    final before = current.eventDate;
    if (!scope.applies || before == null) return const [];

    final heads = headManager ?? EventHeadDBManager();
    final fetch = fetchAttendance ??
        (String id) => EventSupplementalDBManager(id).fetchAttendance();

    final merged = <String, EventHead>{};
    await Future.wait(scope.ids.map((id) async {
      final found = scope.usesCellGroups
          ? await heads.fetchEarlierHeadsWithCellGroup(
              cellGroupId: id,
              before: before,
              limit: lookbackPosts,
            )
          : await heads.fetchEarlierHeadsWithPostTag(
              tagId: id,
              before: before,
              limit: lookbackPosts,
            );
      for (final head in found) {
        merged.putIfAbsent(head.id, () => head);
      }
    }));

    final posts = merged.values.toList();
    return Future.wait(posts.map((head) async {
      return AttendanceSeriesPost(
        head: head,
        attendance: await fetch(head.id),
      );
    }));
  }

  static List<String> _ids(Iterable<String> raw) =>
      raw.where((id) => id.isNotEmpty).toList();

  static bool _isEarlierInScope(
    EventHead current,
    AttendanceSeriesScope scope,
    EventHead other,
  ) {
    if (other.id == current.id) return false;
    final currentDate = current.eventDate;
    final otherDate = other.eventDate;
    if (currentDate == null || otherDate == null) return false;
    if (!otherDate.isBefore(currentDate)) return false;
    final otherIds = scope.usesCellGroups ? other.cellGroupIDs : other.tagIDs;
    return otherIds.any(scope.ids.contains);
  }

  static int _postsWithUser(List<AttendanceSeriesPost> posts, String userId) {
    var count = 0;
    for (final post in posts) {
      if (post.attendance.hasUserAttendee(userId)) count++;
    }
    return count;
  }

  static int _bestTagCount(
    List<AttendanceSeriesPost> posts,
    List<String> tagIds,
    String userId,
  ) {
    var best = 0;
    for (final tagId in tagIds) {
      var count = 0;
      for (final post in posts) {
        if (post.head.tagIDs.contains(tagId) &&
            post.attendance.hasUserAttendee(userId)) {
          count++;
        }
      }
      if (count > best) best = count;
    }
    return best;
  }

  static AttendanceVisitMark? _markForPrior(int prior) {
    final visit = prior + 1;
    if (visit == 1) return AttendanceVisitMark.first;
    if (visit <= markedVisits) return AttendanceVisitMark.returning;
    return null;
  }
}
