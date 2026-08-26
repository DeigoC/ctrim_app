import 'dart:collection';

import 'user_activity_record.dart';

/// Activity log stored at `users/{uid}/supplemental/activity`.
/// Newest first; capped at [maxStoredRecords].
class UserActivityLog {
  static const int maxStoredRecords = 100;
  static const int publicPreviewCount = 5;

  UserActivityLog([List<UserActivityRecord>? records])
      : _records = List<UserActivityRecord>.from(records ?? const []);

  UserActivityLog.fromMap(final Map<String, dynamic> data) {
    final raw = data['Logs'];
    if (raw is! List) {
      _records = [];
      return;
    }
    _records = raw
        .map((e) =>
            UserActivityRecord.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  late List<UserActivityRecord> _records;

  Map<String, dynamic> toJson() {
    return {'Logs': _records.map((e) => e.toJson()).toList()};
  }

  List<UserActivityRecord> get records => UnmodifiableListView(_records);

  /// Last [publicPreviewCount] entries for the volunteer profile card.
  List<UserActivityRecord> get preview =>
      UnmodifiableListView(_records.take(publicPreviewCount).toList());

  void add({
    required String log,
    required String documentId,
    required DateTime ts,
  }) {
    _records.insert(
      0,
      UserActivityRecord(log: log, ts: ts, documentId: documentId),
    );
    if (_records.length > maxStoredRecords) {
      _records = _records.sublist(0, maxStoredRecords);
    }
  }
}
