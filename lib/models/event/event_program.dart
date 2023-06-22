import 'dart:collection';

class EventRole {
  late String _id, _title, _description;
  late bool _forGuests;
  late int _priority;
  late DateTime _startTime, _finishTime;
  late List<String> _assignedUID;

  EventRole({
    required String id,
    required String title,
    String description = '',
    bool forGuests = true,
    int priority = 0,
    List<String>? assignedUID,
    required DateTime startTime,
    required DateTime finishTime,
  }) {
    _id = id;
    _title = title;
    _description = description;
    _forGuests = forGuests;
    _priority = priority;
    _startTime = startTime;
    _finishTime = finishTime;
    _assignedUID = assignedUID ?? List<String>.empty(growable: true);
  }

  String get id => _id;
  String get title => _title;
  String get description => _description;
  List<String> get assignedUIDs => UnmodifiableListView(_assignedUID);
  int get priorty => _priority;
  DateTime get startTime => _startTime;
  DateTime get finishTime => _finishTime;
  bool get forGuests => _forGuests;

  addAssignee(String uid) => _assignedUID.add(uid);
  bool removeAssignee(String uid) => _assignedUID.remove(uid);

  setStartTime(DateTime newTime) => _startTime = newTime;
  setFinishTime(DateTime newTime) => _finishTime = newTime;
}

class EventProgramDetails {
  late final int _currentID;

  int get currentID => _currentID;
}
