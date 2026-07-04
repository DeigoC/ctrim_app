/// Tracks whether a user is an author or contributor on a post, stored under
/// `users/{uid}/supplemental/posts`.
enum PostOwnership {
  author,
  contributor;

  static PostOwnership fromString(final String value) {
    return PostOwnership.values.firstWhere(
      (e) => e.name == value,
      orElse: () => throw ArgumentError('Unknown post ownership: $value'),
    );
  }
}

class UserPostInvolvement {
  late String _postID;
  late PostOwnership _ownership;

  UserPostInvolvement({
    required String postID,
    required PostOwnership ownership,
  }) {
    _postID = postID;
    _ownership = ownership;
  }

  UserPostInvolvement.fromMap(final Map<String, dynamic> data)
      : _postID = data['id'] as String,
        _ownership = PostOwnership.fromString(data['ownership'] as String);

  Map<String, dynamic> toJson() {
    return {
      'id': _postID,
      'ownership': _ownership.name,
    };
  }

  static List<UserPostInvolvement> listFromFirestore(final List<dynamic> raw) {
    return raw.map((e) => UserPostInvolvement.fromMap(Map<String, dynamic>.from(e as Map))).toList();
  }

  static List<Map<String, dynamic>> listToFirestore(final List<UserPostInvolvement> involvements) {
    return involvements.map((e) => e.toJson()).toList();
  }

  String get postID => _postID;
  PostOwnership get ownership => _ownership;
}
