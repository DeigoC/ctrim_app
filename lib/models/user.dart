import 'dart:collection';

import 'user_activity_log.dart';
import 'user_post_involvement.dart';
import 'user_role_assignment.dart';

/// Profile visibility for the volunteers directory and new assignments.
class UserStatus {
  static const String active = 'active';
  static const String hidden = 'hidden';
  static const String archived = 'archived';

  static const List<String> all = [active, hidden, archived];
}

class User {
  late String _forename,
      _surname,
      _authID,
      _imgSrc,
      _id,
      _location,
      _createdByUserID;
  late bool _isAreaAdmin, _isLeader, _isPlaceholder;
  late String _status;
  late List<String> _tagIDs;
  List<UserRoleAssignment>? _roles;
  List<UserPostInvolvement>? _posts;
  UserActivityLog? _activity;

  User(
      {required String id,
      required String forname,
      required String surname,
      String imgSrc = '',
      String location = 'Belfast',
      bool isAreaAdmin = false,
      bool isLeader = false,
      String authID = '',
      List<String> tagIDs = const [],
      String createdByUserID = '',
      bool isPlaceholder = false,
      String status = UserStatus.active}) {
    _id = id;
    _forename = forname;
    _surname = surname;
    _imgSrc = imgSrc;
    _isAreaAdmin = isAreaAdmin;
    _isLeader = isLeader;
    _location = location;
    _authID = authID;
    _tagIDs = List<String>.from(tagIDs);
    _createdByUserID = createdByUserID;
    _isPlaceholder = isPlaceholder;
    _status = UserStatus.all.contains(status) ? status : UserStatus.active;
  }

  User.fromMap(final String id, final Map<String, dynamic> data)
      : _id = id,
        _forename = data['Forename'],
        _surname = data['Surname'],
        _location = data['Location'],
        _isAreaAdmin = data['IsAreaAdmin'],
        _isLeader = data['IsLeader'],
        _authID = (data['AuthID'] as String?) ?? '',
        _imgSrc = data['ImgSrc'],
        _tagIDs = _parseTagIDs(data['Tags']),
        _createdByUserID = (data['CreatedByUserID'] as String?) ?? '',
        // Linked accounts are never placeholders, even if a stale flag remains.
        _isPlaceholder = ((data['AuthID'] as String?) ?? '').trim().isEmpty &&
            ((data['IsPlaceholder'] as bool?) ?? false),
        _status = _parseStatus(data['Status']);

  static String _parseStatus(final dynamic raw) {
    final value = (raw as String?)?.trim() ?? '';
    return UserStatus.all.contains(value) ? value : UserStatus.active;
  }

  static List<String> _parseTagIDs(final dynamic raw) {
    if (raw is! List) return [];
    return raw.map((e) => e.toString()).toList();
  }

  dynamic toJson() {
    return {
      'Forename': _forename,
      'Surname': _surname,
      'Location': _location,
      'IsAreaAdmin': _isAreaAdmin,
      'IsLeader': isLeader,
      'ImgSrc': _imgSrc,
      'AuthID': _authID,
      'Tags': _tagIDs,
      'CreatedByUserID': _createdByUserID,
      'IsPlaceholder': _isPlaceholder,
      'Status': _status,
    };
  }

  void setImgSrc(final String newImgSrc) => _imgSrc = newImgSrc;
  void setLocation(final String location) => _location = location;
  void setTagIDs(final List<String> tagIDs) =>
      _tagIDs = List<String>.from(tagIDs);
  void setIsPlaceholder(final bool value) => _isPlaceholder = value;
  void setForename(final String value) => _forename = value;
  void setSurname(final String value) => _surname = value;
  void setStatus(final String value) {
    _status = UserStatus.all.contains(value) ? value : UserStatus.active;
  }

  void setRoles(final List<UserRoleAssignment> newRoles) => _roles = newRoles;
  void removeRoles(final List<String> postIDs) =>
      _roles!.removeWhere((e) => postIDs.contains(e.postID));

  void setPosts(final List<UserPostInvolvement> newPosts) => _posts = newPosts;
  void removeAllPosts(final List<String> postIDs) =>
      _posts!.removeWhere((e) => postIDs.contains(e.postID));

  void setActivity(final UserActivityLog log) => _activity = log;

  String get id => _id;
  String get forname => _forename;
  String get surname => _surname;
  String get fullname => '$_forename $_surname';
  String get initials {
    final letters = <String>[
      if (_forename.isNotEmpty) _forename[0],
      ..._surname
          .split('-')
          .where((part) => part.isNotEmpty)
          .map((part) => part[0]),
    ];
    return letters.isEmpty ? '?' : letters.join();
  }

  String get shortenedFullName {
    final surnameParts = _surname
        .split('-')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0])
        .join();
    if (_forename.isEmpty && surnameParts.isEmpty) return '?';
    if (surnameParts.isEmpty) return _forename;
    return '$_forename $surnameParts.';
  }

  String get imgSrc => _imgSrc;
  String get location => _location;
  String get authID => _authID;

  /// Permission flags on the community profile (`IsLeader` / `IsAreaAdmin`).
  /// Area admin is a step above Leader: every admin is a leader.
  /// Cell-group leadership is stored on cell group records, not this document.
  bool get isAreaAdmin => _isAreaAdmin;
  bool get isLeader => _isLeader || _isAreaAdmin;
  String get createdByUserID => _createdByUserID;
  bool get isPlaceholder => _isPlaceholder;
  String get status => _status;
  bool get isProfileActive => _status == UserStatus.active;
  bool get isProfileHidden => _status == UserStatus.hidden;
  bool get isProfileArchived => _status == UserStatus.archived;
  bool get isProfileInactive => !isProfileActive;

  /// Churches, testimonials, and CTRIM info add/edit/delete.
  bool get canManageInfo => isLeader;

  /// Nested church hub pages (area admin). Leaders still edit the church overview.
  bool get canManageChurchPages => _isAreaAdmin;

  /// Register/edit volunteers, user tags, post tags, locations.
  bool get canManageVolunteers => _isAreaAdmin;

  /// Create/edit post templates (and Add Post FAB).
  bool get canManagePostTemplates => isLeader;

  /// Create/edit cell group catalogue records (area admin).
  bool get canManageCellGroups => _isAreaAdmin;

  List<String> get tagIDs => UnmodifiableListView(_tagIDs);

  bool hasTag(final String tagId) => _tagIDs.contains(tagId);
  bool hasAnyTag(final Iterable<String> tagIds) => tagIds.any(_tagIDs.contains);

  List<UserRoleAssignment>? get roles =>
      _roles == null ? null : UnmodifiableListView(_roles!);
  List<UserPostInvolvement>? get posts =>
      _posts == null ? null : UnmodifiableListView(_posts!);
  UserActivityLog? get activity => _activity;
}
