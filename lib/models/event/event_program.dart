import 'dart:collection';

class EventRole {
  late final String _id;
  late String _title, _description;
  late bool _forGuests;
  late int _priority;
  late DateTime _startTime, _finishTime;
  late List<String> _assignedUID;

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

  // Assigned UIDs
  void addAssignee(String uid) => _assignedUID.add(uid);
  bool removeAssignee(String uid) => _assignedUID.remove(uid);

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

  EventProgramDetails({required int currentID, required DateTime finishTime})
      : _currentID = currentID,
        _finishTime = finishTime;

  int get getAndIncrementCurrentID => _currentID++; // TODO test this approach
  DateTime get finishTime => _finishTime;

  void setFinishTime(DateTime newTime) => _finishTime = newTime;
}
