import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';

class EventProgram {
  // * a role is made of 6 fields
  // uids - list of users assigned by their IDs
  // detail - short description of the role
  // start - datetime/timestamp of starting time
  // end - datetime/timestamp of finishing time
  // for_guests - bool to signigfy whether to show to guests or not
  // priority - int to signfy it's importance (higher numbers for significance)
  late final List<Map<String, dynamic>> _roles = List.empty(growable: true);

  DateTime? _finishTime;
  bool _allDay = false;

  void addRole(Map<String, dynamic> role) {
    _roles.add(role);
  }

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
        'start': Timestamp.fromDate(entry['start']),
        'end': Timestamp.fromDate(entry['end']),
        'for_guests': entry['for_guests'],
        'priority': entry['priority'],
      });
    }

    return result;
  }

  List<Map<String, dynamic>> get roles => _roles; // unmodifiable?

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

class EventRole {
  late final String _id;
  late String _title, _description;
  late bool _forGuests;
  late int _priority;
  late DateTime _startTime, _finishTime;
  late List<String> _assignedUIDs;

  EventRole({
    required String id,
    required String title,
    required DateTime startTime,
    required DateTime finishTime,
    String description = '',
    bool forGuests = true,
    int priority = 0,
    List<String>? assignedUID,
  }) {
    _id = id;
    _title = title;
    _description = description;
    _forGuests = forGuests;
    _priority = priority;
    _startTime = startTime;
    _finishTime = finishTime;
    _assignedUIDs = assignedUID ?? List<String>.empty(growable: true);
  }

  EventRole.fromMap(String id, Map<String, dynamic> data)
      : _id = id,
        _title = data['Title'],
        _description = data['Description'],
        _forGuests = data['ForGuests'],
        _priority = data['Priority'],
        _startTime = (data['StartTime'] as Timestamp).toDate(),
        _finishTime = (data['FinishTime'] as Timestamp).toDate(),
        _assignedUIDs = List.from(data['AssinedUIDs']);

  toJson() {
    return {
      'Title': _title,
      'Description': _description,
      'ForGuests': _forGuests,
      'Priority': _priority,
      'StartTime': Timestamp.fromDate(_startTime),
      'FinishTime': Timestamp.fromDate(_finishTime),
      'AssinedUIDs': _assignedUIDs
    };
  }

  String get id => _id;
  String get title => _title;
  String get description => _description;
  List<String> get assignedUIDs => UnmodifiableListView(_assignedUIDs);
  int get priorty => _priority;
  DateTime get startTime => _startTime;
  DateTime get finishTime => _finishTime;
  bool get forGuests => _forGuests;

  // Assigned UIDs
  void addAssignee(String uid) => _assignedUIDs.add(uid);
  bool removeAssignee(String uid) => _assignedUIDs.remove(uid);

  // Time related
  void setStartTime(DateTime newTime) => _startTime = newTime;
  void setFinishTime(DateTime newTime) => _finishTime = newTime;

  // Text stuff
  void setTitle(String newTitle) => _title = title;
  void setDescription(String newDescription) => _description = newDescription;

  // Priority and Guest stuff
  void setPriority(int newPriority) => _priority = newPriority;
  void setForGuest(bool forGuest) => _forGuests = forGuest;
}

class EventProgramDetails {
  late final int _currentID;
  DateTime? _finishTime;
  bool _allDay = false;

  EventProgramDetails() {
    _currentID = 1;
  }

  EventProgramDetails.fromMap(Map<String, dynamic> data)
      : _currentID = data['CurrentID'],
        _allDay = data['AllDay'],
        _finishTime = (data['FinishTime'] as Timestamp).toDate(); // this might break

  toJson() {
    return {
      'CurrentID': _currentID,
      'AllDay': _allDay,
      'FinishTime': _finishTime == null ? null : Timestamp.fromDate(_finishTime!)
    };
  }

  int get getAndIncrementCurrentID => _currentID++; // TODO test this approach
  DateTime? get finishTime => _finishTime;
  bool get allDay => _allDay;

  void setFinishTime(DateTime newTime) => _finishTime = newTime;
  void toggleAllday() => _allDay = !_allDay;
}
