import 'package:cloud_firestore/cloud_firestore.dart';

/// One row in `users/{uid}/supplemental/activity`.
///
/// [title] is the record's name when the action happened, so a deleted or
/// renamed record still reads sensibly. [note] is the editor's short update
/// (post saves). [parentId] is the owning record when [documentId] alone
/// cannot be opened (church page → church). Older rows have none of these.
class UserActivityRecord {
  late String _log, _documentId, _title, _note, _parentId;
  late DateTime _ts;

  UserActivityRecord({
    required String log,
    required DateTime ts,
    required String documentId,
    String title = '',
    String note = '',
    String parentId = '',
  }) {
    _log = log;
    _ts = ts;
    _documentId = documentId;
    _title = title.trim();
    _note = note.trim();
    _parentId = parentId.trim();
  }

  UserActivityRecord.fromMap(final Map<String, dynamic> data)
      : _log = (data['log'] as String?) ?? '',
        _documentId = (data['documentId'] as String?) ?? '',
        _title = (data['title'] as String?) ?? '',
        _note = (data['note'] as String?) ?? '',
        _parentId = (data['parentId'] as String?) ?? '',
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
      if (_title.isNotEmpty) 'title': _title,
      if (_note.isNotEmpty) 'note': _note,
      if (_parentId.isNotEmpty) 'parentId': _parentId,
    };
  }

  String get log => _log;
  DateTime get ts => _ts;
  String get documentId => _documentId;
  String get title => _title;
  String get note => _note;
  String get parentId => _parentId;
}
