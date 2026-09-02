import '../models/cell_group.dart';
import '../models/user.dart';

/// Volunteer roles shown in the directory. Area admin is a step above Leader
/// (every admin is a leader). Cell-group leadership is derived from cell
/// group records.
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
      if (user.isAreaAdmin)
        VolunteerRoleKind.areaAdmin
      else if (user.isLeader)
        VolunteerRoleKind.leader,
      if (cellGroupLeaders.contains(user)) VolunteerRoleKind.cellGroupLeader,
    };
  }

  /// Leader and Area Admin are mutually exclusive in the filter UI (Admin is
  /// a subset of Leader). Cell-group leader can combine with either.
  static Set<VolunteerRoleKind> toggleRole({
    required Set<VolunteerRoleKind> current,
    required VolunteerRoleKind role,
  }) {
    final next = Set<VolunteerRoleKind>.from(current);
    if (next.contains(role)) {
      next.remove(role);
      return next;
    }
    next.add(role);
    if (role == VolunteerRoleKind.leader) {
      next.remove(VolunteerRoleKind.areaAdmin);
    } else if (role == VolunteerRoleKind.areaAdmin) {
      next.remove(VolunteerRoleKind.leader);
    }
    return next;
  }

  /// Whether [user] should appear in the default People directory / serving
  /// pickers. Derived from Leader/Admin, team tags, or cell-group leadership
  /// — not a separate stored flag.
  static bool userServes({
    required User user,
    required CellGroupLeaderIndex cellGroupLeaders,
  }) {
    if (user.isLeader) return true;
    if (user.tagIDs.isNotEmpty) return true;
    return cellGroupLeaders.contains(user);
  }

  /// Empty [selected] matches everyone. Otherwise the user must have any of
  /// the selected roles (OR within this filter). The Leaders filter includes
  /// area admins.
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
