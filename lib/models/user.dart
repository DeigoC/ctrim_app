import 'dart:collection';

class User {
  late String _forename, _surname, _authID, _imgSrc, _id, _location;
  late bool _isAreaAdmin, _isLeader;
  List<Map<String, dynamic>>? _roles, _posts;

  User({
    required String id,
    required String forname,
    required String surname,
    String imgSrc = '',
    String location = 'Belfast',
    bool isAreaAdmin = false,
    bool isLeader = false,
    String authID = '',
  }) {
    _id = id;
    _forename = forname;
    _surname = surname;
    _imgSrc = imgSrc;
    _isAreaAdmin = isAreaAdmin;
    _isLeader = isLeader;
    _location = location;
    _authID = authID;
  }

  User.fromMap(String id, Map<String, dynamic> data)
      : _id = id,
        _forename = data['Forename'],
        _surname = data['Surname'],
        _location = data['Location'],
        _isAreaAdmin = data['IsAreaAdmin'],
        _isLeader = data['IsLeader'],
        _authID = data['AuthID'],
        _imgSrc = data['ImgSrc'];

  toJson() {
    return {
      'Forename': _forename,
      'Surname': _surname,
      'Location': _location,
      'IsAreaAdmin': _isAreaAdmin,
      'IsLeader': _isLeader,
      'ImgSrc': _imgSrc,
      'AuthID': _authID,
    };
  }

  void setImgSrc(final String newImgSrc) => _imgSrc = newImgSrc;

  void setRoles(final List<Map<String, dynamic>> newRoles) => _roles = newRoles;
  void removeRoles(final List<String> postIDs) => _roles!.removeWhere((e) => postIDs.contains(e['postID']));

  void setPosts(final List<Map<String, dynamic>> newPosts) => _posts = newPosts;
  void removeAllPosts(final List<String> allPosts) => _posts!.removeWhere((e) => allPosts.contains(e['id']));

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

  List<Map<String, dynamic>>? get roles => _roles == null ? null : UnmodifiableListView(_roles!);
  List<Map<String, dynamic>>? get posts => _posts == null ? null : UnmodifiableListView(_posts!);
}
