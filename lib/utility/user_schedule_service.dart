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

  /// Post IDs whose role assignments are no longer relevant (past event or unknown post).
  static List<String> staleRolePostIDs({
    required User user,
    required List<EventHead> eventHeads,
    DateTime? now,
  }) {
    final roles = user.roles;
    if (roles == null || roles.isEmpty) return [];

    final clock = now ?? DateTime.now();
    final Set<String> postIDs = {};

    for (final roleEntry in roles) {
      final postID = roleEntry.postID;
      final head = _headForPost(eventHeads, postID);
      if (head == null) {
        postIDs.add(postID);
      } else if (head.eventDate != null && head.eventDate!.add(const Duration(days: 1)).isBefore(clock)) {
        postIDs.add(postID);
      }
    }

    return postIDs.toList();
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

  /// Role assignments that are still upcoming (not stale), sorted by start time.
  static List<UserRoleAssignment> upcomingRoles({
    required User user,
    required List<EventHead> eventHeads,
    DateTime? now,
    int? limit,
  }) {
    final roles = user.roles;
    if (roles == null || roles.isEmpty) return [];

    final stalePostIDs = staleRolePostIDs(user: user, eventHeads: eventHeads, now: now).toSet();
    final upcoming = roles.where((role) => !stalePostIDs.contains(role.postID)).toList()
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
    final roles = user.roles;
    if (roles == null || roles.isEmpty) return 0;

    final stalePostIDs = staleRolePostIDs(user: user, eventHeads: eventHeads, now: now).toSet();
    return roles.map((role) => role.postID).where((postID) => !stalePostIDs.contains(postID)).toSet().length;
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
