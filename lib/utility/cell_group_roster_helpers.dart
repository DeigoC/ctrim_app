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
}
