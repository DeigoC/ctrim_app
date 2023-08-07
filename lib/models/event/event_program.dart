import 'package:cloud_firestore/cloud_firestore.dart';

class EventProgram {
  // * a role is made of 6 fields
  // uids - list of users assigned by their IDs
  // title - short title of the role
  // detail (optional) - more text to describe the role
  // start - datetime/timestamp of starting time
  // end - datetime/timestamp of finishing time
  // for_guests - bool to signigfy whether to show to guests or not
  // priority - int to signfy it's importance (higher numbers for significance)
  // ! NOTE: start is optional, but if it exists then end must also be a thing
  final List<Map<String, dynamic>> _roles = List.empty(growable: true);

  DateTime? _finishTime;
  bool _allDay = false;

  EventProgram();

  EventProgram.fromMap(Map<String, dynamic> data) {
    if (data['FinishTime'] != null) {
      _finishTime = (data['FinishTime'] as Timestamp).toDate();
    }
    _allDay = data['AllDay'];

    final List<Map<String, dynamic>> rawData = List<Map<String, dynamic>>.from(data['Roles']);
    for (final entry in rawData) {
      _roles.add({
        'uids': List<String>.from(entry['uids']),
        'detail': entry['detail'],
        'title': entry['title'],
        'start': (entry['start'] as Timestamp).toDate(),
        'end': (entry['end'] as Timestamp).toDate(),
        'for_guests': entry['for_guests'],
        'priority': entry['priority'],
      });
    }
  }

  toJson() {
    return {
      'AllDay': _allDay,
      'FinishTime': _finishTime == null ? null : Timestamp.fromDate(_finishTime!),
      'Roles': _roleToJson(),
    };
  }

  List<Map<String, dynamic>> _roleToJson() {
    final List<Map<String, dynamic>> result = List<Map<String, dynamic>>.empty(growable: true);
    for (final entry in _roles) {
      result.add({
        'uids': entry['uids'],
        'detail': entry['detail'],
        'title': entry['title'],
        'start': Timestamp.fromDate(entry['start']),
        'end': Timestamp.fromDate(entry['end']),
        'for_guests': entry['for_guests'],
        'priority': entry['priority'],
      });
    }

    return result;
  }

  List<Map<String, dynamic>> get roles => _roles; // TODO make this unmodifiable
  bool get allDay => _allDay;
  DateTime? get finishTime => _finishTime;

  void setAllDay(final bool state) => _allDay = state;
  void setFinishTime(final DateTime? finish) => _finishTime = finish;
  void orderProgramsByStartDate() =>
      _roles.sort(((a, b) => (a['start'] as DateTime).compareTo(b['start'] as DateTime)));

  void addRole(final Map<String, dynamic> role) {
    _roles.add(role);
  }

  void removeRole(final List<String> uids, final String title) {}

  @override
  String toString() {
    final String finishString = _finishTime == null ? 'No finish datetime' : 'Finish datetime is $_finishTime';
    String result = '$finishString\n$_allDay';
    for (final roleEntry in _roles) {
      result += '\n Role Entry';
      result += 'UIDs ${List.from(roleEntry['uids'])}';
      result += ' StartTime is ${roleEntry['start'] as DateTime}';
    }
    return result;
  }
}
