import '../models/cell_group.dart';
import '../models/user.dart';

/// Volunteer roles shown in the directory. Leader / Area Admin are flags on
/// [User]. Cell-group leadership is derived from cell group records.
enum VolunteerRoleKind { leader, areaAdmin, cellGroupLeader }

/// Precomputed cell-group leadership lookup (active + paused groups only).
class CellGroupLeaderIndex {
  CellGroupLeaderIndex._(this._userIds, this._authIds);

  final Set<String> _userIds;
  final Set<String> _authIds;

  factory CellGroupLeaderIndex.fromGroups(Iterable<CellGroup> groups) {
    final userIds = <String>{};
    final authIds = <String>{};
    for (final group in groups) {
      if (group.isArchived) continue;
      userIds.addAll(group.leaderUserIds);
      authIds.addAll(group.leaderAuthIds);
    }
    return CellGroupLeaderIndex._(userIds, authIds);
  }

  bool get isEmpty => _userIds.isEmpty && _authIds.isEmpty;

  bool contains(User user) {
    if (user.id.isNotEmpty && _userIds.contains(user.id)) return true;
    final authId = user.authID.trim();
    return authId.isNotEmpty && _authIds.contains(authId);
  }
}

/// Helpers for resolving and filtering volunteer roles without duplicating
/// cell-group leadership onto the user document.
class VolunteerRoleHelpers {
  VolunteerRoleHelpers._();

  static Set<VolunteerRoleKind> rolesFor({
    required User user,
    required CellGroupLeaderIndex cellGroupLeaders,
  }) {
    return {
      if (user.isLeader) VolunteerRoleKind.leader,
      if (user.isAreaAdmin) VolunteerRoleKind.areaAdmin,
      if (cellGroupLeaders.contains(user)) VolunteerRoleKind.cellGroupLeader,
    };
  }

  /// Empty [selected] matches everyone. Otherwise the user must have any of
  /// the selected roles (OR within this filter).
  static bool userMatchesRoleFilter({
    required User user,
    required Set<VolunteerRoleKind> selected,
    required CellGroupLeaderIndex cellGroupLeaders,
  }) {
    if (selected.isEmpty) return true;
    return selected.any((role) {
      return switch (role) {
        VolunteerRoleKind.leader => user.isLeader,
        VolunteerRoleKind.areaAdmin => user.isAreaAdmin,
        VolunteerRoleKind.cellGroupLeader => cellGroupLeaders.contains(user),
      };
    });
  }
}
