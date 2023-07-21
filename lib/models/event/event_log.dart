import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';

class EventLog {
  // * a log will have the following fields
  // uid - string id of the user performing the update
  // log - the short string explaining the change
  // ts - timestamp (DateTime) of when it took place - this becomes the recentDate as well!
  final List<Map<String, dynamic>> _logs = List<Map<String, dynamic>>.empty(growable: true);

  EventLog.fromMap(Map<String, dynamic> data) {
    final List<Map<String, dynamic>> rawData = List<Map<String, dynamic>>.from(data['Logs']);
    for (final entry in rawData) {
      _logs.add({
        'uid': entry['uid'],
        'log': entry['log'],
        'ts': (entry['ts'] as Timestamp).toDate(),
      });
    }
  }

  toJson() {
    return {'Logs': _roleToJson()};
  }

  List<Map<String, dynamic>> _roleToJson() {
    final List<Map<String, dynamic>> result = List<Map<String, dynamic>>.empty(growable: true);
    for (final entry in _logs) {
      result.add({'uid': entry['uid'], 'log': entry['log'], 'ts': Timestamp.fromDate(entry['ts'])});
    }

    return result;
  }

  List<Map<String, dynamic>> get logs => UnmodifiableListView(_logs);
  void addLog(Map<String, dynamic> log) => _logs.add(log);
}
