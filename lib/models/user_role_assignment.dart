/// A denormalized program role assigned to a user, stored under
/// `users/{uid}/supplemental/roles`.
class UserRoleAssignment {
  late String _postID, _title;
  late int _roleID;
  late DateTime _start, _end;

  UserRoleAssignment({
    required String postID,
    required int roleID,
    required DateTime start,
    required DateTime end,
    required String title,
  }) {
    _postID = postID;
    _roleID = roleID;
    _start = start;
    _end = end;
    _title = title;
  }

  UserRoleAssignment.fromMap(final Map<String, dynamic> data)
      : _postID = data['postID'] as String,
        _roleID = (data['id'] as num).toInt(),
        _start = DateTime.fromMillisecondsSinceEpoch((data['startMil'] as num).toInt()),
        _end = DateTime.fromMillisecondsSinceEpoch((data['endMil'] as num).toInt()),
        _title = data['title'] as String;

  Map<String, dynamic> toJson() {
    return {
      'postID': _postID,
      'id': _roleID,
      'startMil': _start.millisecondsSinceEpoch,
      'endMil': _end.millisecondsSinceEpoch,
      'title': _title,
    };
  }

  static List<UserRoleAssignment> listFromFirestore(final List<dynamic> raw) {
    return raw.map((e) => UserRoleAssignment.fromMap(Map<String, dynamic>.from(e as Map))).toList();
  }

  static List<Map<String, dynamic>> listToFirestore(final List<UserRoleAssignment> assignments) {
    return assignments.map((e) => e.toJson()).toList();
  }

  String get postID => _postID;
  int get roleID => _roleID;
  DateTime get start => _start;
  DateTime get end => _end;
  String get title => _title;
}
