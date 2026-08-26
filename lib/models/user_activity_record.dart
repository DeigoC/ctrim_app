import 'package:cloud_firestore/cloud_firestore.dart';

/// One row in `users/{uid}/supplemental/activity`.
class UserActivityRecord {
  late String _log, _documentId;
  late DateTime _ts;

  UserActivityRecord({
    required String log,
    required DateTime ts,
    required String documentId,
  }) {
    _log = log;
    _ts = ts;
    _documentId = documentId;
  }

  UserActivityRecord.fromMap(final Map<String, dynamic> data)
      : _log = (data['log'] as String?) ?? '',
        _documentId = (data['documentId'] as String?) ?? '',
        _ts = _parseTs(data['ts']);

  static DateTime _parseTs(final dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  Map<String, dynamic> toJson() {
    return {
      'log': _log,
      'ts': Timestamp.fromDate(_ts),
      'documentId': _documentId,
    };
  }

  String get log => _log;
  DateTime get ts => _ts;
  String get documentId => _documentId;
}
