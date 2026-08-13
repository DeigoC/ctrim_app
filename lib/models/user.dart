import 'dart:collection';

import 'user_post_involvement.dart';
import 'user_role_assignment.dart';

class User {
  late String _forename, _surname, _authID, _imgSrc, _id, _location, _createdByUserID;
  late bool _isAreaAdmin, _isLeader, _isPlaceholder;
  late List<String> _tagIDs;
  List<UserRoleAssignment>? _roles;
  List<UserPostInvolvement>? _posts;

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
      bool isPlaceholder = false}) {
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
            ((data['IsPlaceholder'] as bool?) ?? false);

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
      'IsLeader': _isLeader,
      'ImgSrc': _imgSrc,
      'AuthID': _authID,
      'Tags': _tagIDs,
      'CreatedByUserID': _createdByUserID,
      'IsPlaceholder': _isPlaceholder,
    };
  }

  void setImgSrc(final String newImgSrc) => _imgSrc = newImgSrc;
  void setLocation(final String location) => _location = location;
  void setTagIDs(final List<String> tagIDs) => _tagIDs = List<String>.from(tagIDs);
  void setIsPlaceholder(final bool value) => _isPlaceholder = value;
  void setForename(final String value) => _forename = value;
  void setSurname(final String value) => _surname = value;

  void setRoles(final List<UserRoleAssignment> newRoles) => _roles = newRoles;
  void removeRoles(final List<String> postIDs) => _roles!.removeWhere((e) => postIDs.contains(e.postID));

  void setPosts(final List<UserPostInvolvement> newPosts) => _posts = newPosts;
  void removeAllPosts(final List<String> postIDs) => _posts!.removeWhere((e) => postIDs.contains(e.postID));

  String get id => _id;
  String get forname => _forename;
  String get surname => _surname;
  String get fullname => '$_forename $_surname';
  String get initials => _forename[0] + _surname.split('-').map((e) => e[0]).join('');
  String get shortenedFullName => '$_forename ${_surname.split('-').map((e) => e[0]).join('')}.';
  String get imgSrc => _imgSrc;
  String get location => _location;
  String get authID => _authID;
  bool get isAreaAdmin => _isAreaAdmin;
  bool get isLeader => _isLeader;
  String get createdByUserID => _createdByUserID;
  bool get isPlaceholder => _isPlaceholder;

  /// Churches, testimonials, and CTRIM info add/edit/delete.
  bool get canManageInfo => _isAreaAdmin || _isLeader;

  /// Register/edit volunteers, user tags, post tags, locations.
  bool get canManageVolunteers => _isAreaAdmin;

  /// Create/edit post templates (and Add Post FAB).
  bool get canManagePostTemplates => _isLeader;

  /// Create/edit cell group catalogue records (area admin).
  bool get canManageCellGroups => _isAreaAdmin;

  List<String> get tagIDs => UnmodifiableListView(_tagIDs);

  bool hasTag(final String tagId) => _tagIDs.contains(tagId);
  bool hasAnyTag(final Iterable<String> tagIds) => tagIds.any(_tagIDs.contains);

  List<UserRoleAssignment>? get roles => _roles == null ? null : UnmodifiableListView(_roles!);
  List<UserPostInvolvement>? get posts => _posts == null ? null : UnmodifiableListView(_posts!);
}
