import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Role values for [CellGroupRosterMember.role].
class CellGroupMemberRole {
  static const String member = 'member';
  static const String leader = 'leader';
  static const String host = 'host';
}

/// Status values for [CellGroupRosterMember.status].
class CellGroupMemberStatus {
  static const String active = 'active';
  static const String inactive = 'inactive';
}

/// One row on a cell group roster (registered or placeholder user).
///
/// Free-text rows (`DisplayName` only) are legacy-read only; new adds use a
/// linked `UserId` (registered or placeholder).
class CellGroupRosterMember {
  late String _userId, _displayName, _role, _status;
  DateTime? _joinedAt;

  CellGroupRosterMember({
    String userId = '',
    String displayName = '',
    String role = CellGroupMemberRole.member,
    String status = CellGroupMemberStatus.active,
    DateTime? joinedAt,
  }) {
    _userId = userId;
    _displayName = displayName;
    _role = role;
    _status = status;
    _joinedAt = joinedAt;
  }

  CellGroupRosterMember.fromMap(final Map<String, dynamic> data)
      : _userId = (data['UserId'] as String?) ?? '',
        _displayName = (data['DisplayName'] as String?) ?? '',
        _role = (data['Role'] as String?) ?? CellGroupMemberRole.member,
        _status = (data['Status'] as String?) ?? CellGroupMemberStatus.active,
        _joinedAt = _parseTimestamp(data['JoinedAt']);

  static DateTime? _parseTimestamp(final dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'UserId': _userId,
      'DisplayName': _displayName,
      'Role': _role,
      'Status': _status,
      if (_joinedAt != null) 'JoinedAt': Timestamp.fromDate(_joinedAt!),
    };
  }

  String get userId => _userId;
  String get displayName => _displayName;
  String get role => _role;
  String get status => _status;
  DateTime? get joinedAt => _joinedAt;

  bool get isLinkedUser => _userId.isNotEmpty;
  bool get isFreeText => _userId.isEmpty && _displayName.trim().isNotEmpty;
  bool get isActive => _status == CellGroupMemberStatus.active;

  void setDisplayName(final String name) => _displayName = name;
  void setRole(final String role) => _role = role;
  void setStatus(final String status) => _status = status;
}

/// Private roster supplemental doc: `cell_groups/{id}/supplemental/roster`.
class CellGroupRoster {
  late List<CellGroupRosterMember> _members;

  CellGroupRoster({List<CellGroupRosterMember> members = const []}) {
    _members = List<CellGroupRosterMember>.from(members);
  }

  CellGroupRoster.fromMap(final Map<String, dynamic> data) {
    final raw = data['Members'];
    if (raw is! List) {
      _members = <CellGroupRosterMember>[];
      return;
    }
    _members = raw
        .whereType<Map>()
        .map((e) => CellGroupRosterMember.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'Members': _members.map((m) => m.toJson()).toList(),
    };
  }

  List<CellGroupRosterMember> get members => UnmodifiableListView(_members);

  List<CellGroupRosterMember> get activeMembers =>
      _members.where((m) => m.isActive).toList();

  int get activeCount => activeMembers.length;

  bool containsUserId(final String userId) =>
      userId.isNotEmpty && _members.any((m) => m.userId == userId);

  void setMembers(final List<CellGroupRosterMember> members) {
    _members = List<CellGroupRosterMember>.from(members);
  }

  void addMember(final CellGroupRosterMember member) => _members.add(member);

  void removeAt(final int index) => _members.removeAt(index);

  void removeWhere(bool Function(CellGroupRosterMember) test) =>
      _members.removeWhere(test);
}
