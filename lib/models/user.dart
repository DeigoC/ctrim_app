class User {
  late String _forename, _surname, _imgSrc, _id, _location;
  late bool _isAreaAdmin, _isLeader;

  User({
    required String id,
    required String forname,
    required String surname,
    String imgSrc = '',
    bool isAreaAdmin = false,
    bool isLeader = false,
  }) {
    _id = id;
    _forename = forname;
    _surname = surname;
    _imgSrc = imgSrc;
    _isAreaAdmin = isAreaAdmin;
    _isLeader = isLeader;
    _location = 'Belfast';
  }

  User.fromMap(String id, Map<String, dynamic> data)
      : _id = id,
        _forename = data['Forename'],
        _surname = data['Surname'],
        _location = data['Location'],
        _isAreaAdmin = data['IsAreaAdmin'],
        _isLeader = data['IsLeader'],
        _imgSrc = data['ImgSrc'];

  toJson() {
    return {
      'Forename': _forename,
      'Surname': _surname,
      'Location': _location,
      'IsAreaAdmin': _isAreaAdmin,
      'IsLeader': _isLeader,
      'ImgSrc': _imgSrc,
    };
  }

  void setName(String? forname, String? surname) {
    if (forname != null) _forename = forname;
    if (surname != null) _surname = surname;
  }

  void setImgSrc(String newImgSrc) => _imgSrc = newImgSrc;

  String get id => _id;
  String get forname => _forename;
  String get surname => _surname;
  String get fullname => '$_forename $_surname';
  String get imgSrc => _imgSrc;
  bool get isAreaAdmin => _isAreaAdmin;
  bool get isLeader => _isLeader;
}
