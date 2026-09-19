import '../models/cell_group.dart';
import '../models/user.dart';
import 'cell_group_roster_cache.dart';

/// Shared roster lookups for cell-group membership expansion.
abstract final class CellGroupRosterHelpers {
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
