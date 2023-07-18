class UserContact {
  late final String _authID, _email, _id;
  late final List<String> _deviceTokens;

  UserContact({
    required String authID,
    required String id,
    required String email,
  }) {
    _id = id;
    _authID = authID;
    _email = email;
    _deviceTokens = List<String>.empty(growable: true);
  }

  UserContact.fromMap(String id, Map<String, dynamic> data)
      : _id = id,
        _authID = data['AuthID'],
        _deviceTokens = List.from(data['Tokens']),
        _email = data['Email'];

  toJson() {
    return {
      'AuthID': _authID,
      'Tokens': _deviceTokens,
      'Email': _email,
    };
  }

  addToken(String newToken) => _deviceTokens.add(newToken);
  removeToken(String token) => _deviceTokens.remove(token);

  String get authID => _authID;
  String get id => _id;
  String get email => _email;
  List<String> get deviceTokens => _deviceTokens;
}
