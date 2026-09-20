import '../models/cell_group.dart';
import '../models/user.dart';
import 'cell_group_roster_cache.dart';

/// Shared roster lookups for cell-group membership expansion.
abstract final class CellGroupRosterHelpers {
  /// Linked roster members per group, capped for avatar stacks (signed-in).
  static Future<Map<String, List<User>>> linkedRosterUsersByGroupId({
    required Iterable<CellGroup> groups,
    required List<User> allUsers,
    required bool isGuest,
    int maxFaces = 8,
  }) async {
    if (isGuest) {
      return const {};
    }

    final active = groups.where((g) => !g.isArchived).toList();
    if (active.isEmpty) {
      return const {};
    }

    await CellGroupRosterCache.ensureLoaded(active.map((g) => g.id));

    final byId = <String, User>{
      for (final user in allUsers) user.id: user,
    };
    final result = <String, List<User>>{};
    for (final group in active) {
      final roster = CellGroupRosterCache.rosterFor(group.id);
      if (roster == null) {
        result[group.id] = const [];
        continue;
      }
      final users = <User>[];
      for (final member in roster.activeMembers) {
        if (!member.isLinkedUser) {
          continue;
        }
        final user = byId[member.userId];
        if (user != null) {
          users.add(user);
        }
        if (users.length >= maxFaces) {
          break;
        }
      }
      result[group.id] = users;
    }
    return result;
  }

  /// Active linked [UserId]s from one or more cell group rosters.
  static Future<Set<String>> fetchActiveLinkedUserIds(
    Iterable<String> cellGroupIds,
  ) async {
    await CellGroupRosterCache.ensureLoaded(cellGroupIds);
    final ids = <String>{};
    for (final cgId in cellGroupIds) {
      if (cgId.isEmpty) continue;
      final roster = CellGroupRosterCache.rosterFor(cgId);
      if (roster == null) continue;
      for (final member in roster.members) {
        if (member.isLinkedUser && member.isActive) {
          ids.add(member.userId);
        }
      }
    }
    return ids;
  }

  /// Active linked roster user ids across non-archived groups [actor] leads.
  static Set<String> activeLinkedUserIdsLedBy({
    required User actor,
    required Iterable<CellGroup> catalogue,
  }) {
    final ids = <String>{};
    final actorId = actor.id;
    final actorAuth = actor.authID.trim();
    if (actorId.isEmpty && actorAuth.isEmpty) return ids;

    for (final group in catalogue) {
      if (group.isArchived) continue;
      final isLeader = group.isLeaderUser(actorId) ||
          (actorAuth.isNotEmpty && group.isLeaderAuth(actorAuth));
      if (!isLeader) continue;
      final roster = CellGroupRosterCache.rosterFor(group.id);
      if (roster == null) continue;
      for (final member in roster.members) {
        if (member.isLinkedUser && member.isActive) {
          ids.add(member.userId);
        }
      }
    }
    return ids;
  }

  /// Whether [actor] is a listed leader of a non-archived group whose active
  /// roster includes [targetUserId].
  static bool actorLeadsGroupContainingUser({
    required User actor,
    required String targetUserId,
    required Iterable<CellGroup> catalogue,
  }) {
    if (targetUserId.isEmpty) return false;
    return activeLinkedUserIdsLedBy(actor: actor, catalogue: catalogue)
        .contains(targetUserId);
  }
}
