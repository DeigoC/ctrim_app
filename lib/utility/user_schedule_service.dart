import 'package:flutter/foundation.dart';

import '../firebase/db_managers/user_db_manager.dart';
import '../models/event/event_head.dart';
import '../models/user.dart';
import '../models/user_post_involvement.dart';
import '../models/user_role_assignment.dart';

/// Centralises supplemental user schedule/post cleanup and refresh.
class UserScheduleService {
  UserScheduleService({UserDBManager? userDBManager}) : _userDBManager = userDBManager ?? UserDBManager();

  final UserDBManager _userDBManager;

  /// After the event date, roles stay "current" for this grace period (same-day wrap-up).
  static const Duration rolePastGrace = Duration(days: 1);

  /// How long past assignments stay on the user schedule for organisers before prune.
  static const Duration roleRetention = Duration(days: 28);

  /// Post IDs whose role assignments should be removed (beyond retention only).
  static List<String> staleRolePostIDs({
    required User user,
    required List<EventHead> eventHeads,
    DateTime? now,
  }) {
    final roles = user.roles;
    if (roles == null || roles.isEmpty) return [];

    final clock = now ?? DateTime.now();
    final Set<String> postIDs = {};

    for (final postID in _distinctPostIDs(roles)) {
      if (isBeyondRetentionForPost(
        user: user,
        postID: postID,
        eventHeads: eventHeads,
        now: clock,
      )) {
        postIDs.add(postID);
      }
    }

    return postIDs.toList();
  }

  /// True when the assignment anchor date is past the grace window.
  static bool isPastSchedulePost({
    required User user,
    required String postID,
    required List<EventHead> eventHeads,
    DateTime? now,
  }) {
    final anchor = _scheduleAnchorDate(
      user: user,
      postID: postID,
      eventHeads: eventHeads,
    );
    if (anchor == null) return false;
    final clock = now ?? DateTime.now();
    return anchor.add(rolePastGrace).isBefore(clock);
  }

  /// True when the event is past the grace window (still retained until [roleRetention]).
  static bool isPastScheduleHead(EventHead head, {DateTime? now}) {
    final clock = now ?? DateTime.now();
    final eventDate = head.eventDate;
    if (eventDate == null) return false;
    return eventDate.add(rolePastGrace).isBefore(clock);
  }

  /// True when the post is old enough that roles should be pruned.
  static bool isBeyondRetentionForPost({
    required User user,
    required String postID,
    required List<EventHead> eventHeads,
    DateTime? now,
  }) {
    final anchor = _scheduleAnchorDate(
      user: user,
      postID: postID,
      eventHeads: eventHeads,
    );
    if (anchor == null) return false;
    final clock = now ?? DateTime.now();
    return anchor.add(roleRetention).isBefore(clock);
  }

  /// True when the event is old enough that roles should be pruned.
  static bool isBeyondRetention(EventHead head, {DateTime? now}) {
    final clock = now ?? DateTime.now();
    final eventDate = head.eventDate;
    if (eventDate == null) return false;
    return eventDate.add(roleRetention).isBefore(clock);
  }

  /// Distinct post IDs with retained upcoming assignments (not past, not prune-stale).
  static List<String> upcomingSchedulePostIDs({
    required User user,
    required List<EventHead> eventHeads,
    DateTime? now,
  }) {
    return _retainedSchedulePostIDs(
      user: user,
      eventHeads: eventHeads,
      now: now,
      past: false,
    );
  }

  /// Distinct post IDs with retained recent-past assignments (within [roleRetention]).
  static List<String> recentPastSchedulePostIDs({
    required User user,
    required List<EventHead> eventHeads,
    DateTime? now,
  }) {
    return _retainedSchedulePostIDs(
      user: user,
      eventHeads: eventHeads,
      now: now,
      past: true,
    );
  }

  static List<String> _retainedSchedulePostIDs({
    required User user,
    required List<EventHead> eventHeads,
    required bool past,
    DateTime? now,
  }) {
    final roles = user.roles;
    if (roles == null || roles.isEmpty) return [];

    final clock = now ?? DateTime.now();
    final stale = staleRolePostIDs(user: user, eventHeads: eventHeads, now: clock).toSet();
    final Set<String> postIDs = {};

    for (final postID in _distinctPostIDs(roles)) {
      if (stale.contains(postID)) continue;

      final isPast = isPastSchedulePost(
        user: user,
        postID: postID,
        eventHeads: eventHeads,
        now: clock,
      );
      if (isPast == past) {
        postIDs.add(postID);
      }
    }

    final sorted = postIDs.toList()
      ..sort((a, b) {
        final aDate = _scheduleAnchorDate(user: user, postID: a, eventHeads: eventHeads);
        final bDate = _scheduleAnchorDate(user: user, postID: b, eventHeads: eventHeads);
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        // Upcoming: soonest first. Recent past: most recent first.
        return past ? bDate.compareTo(aDate) : aDate.compareTo(bDate);
      });

    return sorted;
  }

  /// Post IDs in supplemental posts list that no longer have a loaded event head.
  static List<String> stalePostInvolvementIDs({
    required User user,
    required List<EventHead> eventHeads,
  }) {
    final posts = user.posts;
    if (posts == null || posts.isEmpty) return [];

    return posts.where((e) => !eventHeads.any((head) => head.id == e.postID)).map((e) => e.postID).toList();
  }

  /// Role assignments that are still upcoming (not past, not missing), sorted by start time.
  static List<UserRoleAssignment> upcomingRoles({
    required User user,
    required List<EventHead> eventHeads,
    DateTime? now,
    int? limit,
  }) {
    final roles = user.roles;
    if (roles == null || roles.isEmpty) return [];

    final clock = now ?? DateTime.now();
    final upcomingPostIDs = upcomingSchedulePostIDs(user: user, eventHeads: eventHeads, now: clock).toSet();
    final upcoming = roles.where((role) => upcomingPostIDs.contains(role.postID)).toList()
      ..sort((a, b) => a.start.compareTo(b.start));

    if (limit != null && upcoming.length > limit) {
      return upcoming.sublist(0, limit);
    }
    return upcoming;
  }

  /// Distinct upcoming post IDs — used for schedule badges.
  static int upcomingPostCount({
    required User user,
    required List<EventHead> eventHeads,
    DateTime? now,
  }) {
    return upcomingSchedulePostIDs(user: user, eventHeads: eventHeads, now: now).length;
  }

  /// First [limit] distinct upcoming post IDs (soonest first).
  static List<String> upcomingSchedulePostIDsLimited({
    required User user,
    required List<EventHead> eventHeads,
    DateTime? now,
    int limit = 3,
  }) {
    final ids = upcomingSchedulePostIDs(user: user, eventHeads: eventHeads, now: now);
    if (ids.length <= limit) return ids;
    return ids.sublist(0, limit);
  }

  /// Role count for [postID] on [user]'s upcoming schedule.
  static int roleCountForPost({
    required User user,
    required String postID,
    required List<EventHead> eventHeads,
    DateTime? now,
  }) {
    final upcomingPostIDs =
        upcomingSchedulePostIDs(user: user, eventHeads: eventHeads, now: now).toSet();
    if (!upcomingPostIDs.contains(postID)) return 0;
    final roles = user.roles;
    if (roles == null) return 0;
    return roles.where((role) => role.postID == postID).length;
  }

  static EventHead? eventHeadForRole({
    required String postID,
    required List<EventHead> eventHeads,
  }) =>
      _headForPost(eventHeads, postID);

  static EventHead? _headForPost(final List<EventHead> eventHeads, final String postID) {
    for (final head in eventHeads) {
      if (head.id == postID) return head;
    }
    return null;
  }

  static List<String> _distinctPostIDs(final List<UserRoleAssignment> roles) {
    return roles.map((role) => role.postID).toSet().toList();
  }

  static DateTime? _scheduleAnchorDate({
    required User user,
    required String postID,
    required List<EventHead> eventHeads,
  }) {
    final head = _headForPost(eventHeads, postID);
    if (head?.eventDate != null) return head!.eventDate;

    final roles = user.roles;
    if (roles == null || roles.isEmpty) return null;

    DateTime? earliest;
    for (final role in roles) {
      if (role.postID != postID) continue;
      if (earliest == null || role.start.isBefore(earliest)) {
        earliest = role.start;
      }
    }
    return earliest;
  }

  Future<List<UserRoleAssignment>> fetchRoles(final String uid) => _userDBManager.fetchUserRoles(uid);

  Future<List<UserPostInvolvement>> fetchPosts(final String uid) => _userDBManager.fetchUserPosts(uid);

  /// Removes stale role assignments from [user] and Firestore. Returns true if any were removed.
  Future<bool> pruneStaleRoles({
    required User user,
    required List<EventHead> eventHeads,
    DateTime? now,
  }) async {
    final postIDs = staleRolePostIDs(user: user, eventHeads: eventHeads, now: now);
    if (postIDs.isEmpty) return false;

    debugPrint('removing the following dated roles: $postIDs');
    user.removeRoles(postIDs);
    for (final postID in postIDs) {
      await _userDBManager.removeUserPostRole(user.id, postID);
    }
    return true;
  }

  /// Removes stale post involvements from [user] and Firestore. Returns true if any were removed.
  Future<bool> pruneStalePostInvolvements({
    required User user,
    required List<EventHead> eventHeads,
  }) async {
    final postIDs = stalePostInvolvementIDs(user: user, eventHeads: eventHeads);
    if (postIDs.isEmpty) return false;

    debugPrint('removing the following posts: $postIDs');
    user.removeAllPosts(postIDs);
    await _userDBManager.updatePosts(user);
    return true;
  }
}
