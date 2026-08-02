import 'dart:collection';

import 'user_post_involvement.dart';
import 'user_role_assignment.dart';

class User {
  late String _forename, _surname, _authID, _imgSrc, _id, _location;
  late bool _isAreaAdmin, _isLeader;
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
      List<String> tagIDs = const []}) {
    _id = id;
    _forename = forname;
    _surname = surname;
    _imgSrc = imgSrc;
    _isAreaAdmin = isAreaAdmin;
    _isLeader = isLeader;
    _location = location;
    _authID = authID;
    _tagIDs = List<String>.from(tagIDs);
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
        _tagIDs = _parseTagIDs(data['Tags']);

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
    };
  }

  void setImgSrc(final String newImgSrc) => _imgSrc = newImgSrc;
  void setLocation(final String location) => _location = location;
  void setTagIDs(final List<String> tagIDs) => _tagIDs = List<String>.from(tagIDs);

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
  List<String> get tagIDs => UnmodifiableListView(_tagIDs);

  bool hasTag(final String tagId) => _tagIDs.contains(tagId);
  bool hasAnyTag(final Iterable<String> tagIds) => tagIds.any(_tagIDs.contains);

  List<UserRoleAssignment>? get roles => _roles == null ? null : UnmodifiableListView(_roles!);
  List<UserPostInvolvement>? get posts => _posts == null ? null : UnmodifiableListView(_posts!);
}
