import '../firebase/db_managers/cell_group_db_manager.dart';
import '../models/cell_group.dart';
import '../models/cell_group_roster.dart';
import '../models/user.dart';

/// Session RAM cache of cell group rosters keyed by group id.
///
/// Populated on first need (profile lookup, Cell Groups tab, fill-from-group)
/// and updated when a roster is fetched or saved. Avoids repeat supplemental
/// reads within the same app session.
abstract final class CellGroupRosterCache {
  static final Map<String, CellGroupRoster> _rosters = {};

  static bool isLoaded(String groupId) =>
      groupId.isNotEmpty && _rosters.containsKey(groupId);

  static CellGroupRoster? rosterFor(String groupId) => _rosters[groupId];

  static void put(String groupId, CellGroupRoster roster) {
    if (groupId.isEmpty) return;
    _rosters[groupId] = roster;
  }

  static void invalidate([String? groupId]) {
    if (groupId == null || groupId.isEmpty) {
      _rosters.clear();
      return;
    }
    _rosters.remove(groupId);
  }

  /// Fetches any rosters not yet cached for [groupIds] (parallel).
  static Future<void> ensureLoaded(Iterable<String> groupIds) async {
    final missing = groupIds
        .where((id) => id.isNotEmpty && !_rosters.containsKey(id))
        .toSet()
        .toList();
    if (missing.isEmpty) return;

    await Future.wait(missing.map((id) async {
      try {
        final roster =
            await CellGroupSupplementalDBManager(id).fetchRoster();
        _rosters[id] = roster;
      } catch (_) {
        // Cache empty roster so callers skip repeat failed reads this session.
        _rosters[id] = CellGroupRoster();
      }
    }));
  }

  /// Non-archived groups [user] belongs to — roster member or listed leader.
  static List<CellGroup> groupsForUser({
    required User user,
    required Iterable<CellGroup> catalogue,
  }) {
    final matches = <CellGroup>[];
    for (final group in catalogue) {
      if (group.isArchived) continue;
      if (_userParticipates(user: user, group: group)) {
        matches.add(group);
      }
    }
    matches.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return List<CellGroup>.unmodifiable(matches);
  }

  static bool _userParticipates({
    required User user,
    required CellGroup group,
  }) {
    if (group.isLeaderUser(user.id)) return true;
    final authId = user.authID.trim();
    if (authId.isNotEmpty && group.isLeaderAuth(authId)) return true;

    final roster = _rosters[group.id];
    if (roster == null) return false;
    return roster.members.any(
      (m) => m.isLinkedUser && m.isActive && m.userId == user.id,
    );
  }

  /// Clears cached rosters — for tests only.
  static void resetForTesting() => _rosters.clear();
}
