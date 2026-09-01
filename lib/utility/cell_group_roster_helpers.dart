import '../firebase/db_managers/cell_group_db_manager.dart';

/// Shared roster lookups for cell-group membership expansion.
abstract final class CellGroupRosterHelpers {
  /// Active linked [UserId]s from one or more cell group rosters.
  static Future<Set<String>> fetchActiveLinkedUserIds(
    Iterable<String> cellGroupIds,
  ) async {
    final ids = <String>{};
    for (final cgId in cellGroupIds) {
      if (cgId.isEmpty) continue;
      try {
        final roster = await CellGroupSupplementalDBManager(cgId).fetchRoster();
        for (final member in roster.members) {
          if (member.isLinkedUser && member.isActive) {
            ids.add(member.userId);
          }
        }
      } catch (_) {
        // Roster may be unavailable; skip that group.
      }
    }
    return ids;
  }
}
