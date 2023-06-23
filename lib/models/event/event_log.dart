class EventLog {
  late final String _log, _uid;
  late final DateTime _id;

  EventLog({
    required String log,
    required String uid,
    required DateTime id,
  }) {
    _log = log;
    _id = id;
    _uid = uid;
  }

  EventLog.fromMap(DateTime id, Map<String, dynamic> data)
      : _id = id,
        _uid = data['UID'],
        _log = data['Log'];

  toJson() {
    return {'UID': _uid, 'Log': _log};
  }

  String get log => _log;
  String get uid => _uid;
  DateTime get id => _id;
}
