import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';

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
  late DateTime _finishTime;
  bool _allDay = false;

  EventProgramDetails({required int currentID, required DateTime finishTime})
      : _currentID = currentID,
        _finishTime = finishTime;

  EventProgramDetails.fromMap(Map<String, dynamic> data)
      : _currentID = data['CurrentID'],
        _finishTime = (data['FinishTime'] as Timestamp).toDate();

  toJson() {
    return {'CurrentID': _currentID, 'FinishTime': Timestamp.fromDate(_finishTime)};
  }

  int get getAndIncrementCurrentID => _currentID++; // TODO test this approach
  DateTime get finishTime => _finishTime;
  bool get allDay => _allDay;

  void setFinishTime(DateTime newTime) => _finishTime = newTime;
  void toggleAllday() => _allDay = !_allDay;
}
