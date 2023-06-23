class User {
  late String _forname, _surname, _imgSrc, _id;
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
    _forname = forname;
    _surname = surname;
    _imgSrc = imgSrc;
    _isAreaAdmin = isAreaAdmin;
    _isLeader = isLeader;
  }

  void setName(String? forname, String? surname) {
    if (forname != null) _forname = forname;
    if (surname != null) _surname = surname;
  }

  void setImgSrc(String newImgSrc) => _imgSrc = newImgSrc;

  String get id => _id;
  String get forname => _forname;
  String get surname => _surname;
  String get fullname => '$_forname $_surname';
  String get imgSrc => _imgSrc;
  bool get isAreaAdmin => _isAreaAdmin;
  bool get isLeader => _isLeader;
}
