import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';

class EventProgram {
  // * a role is made of 7 fields
  // uids - list of users assigned by their IDs
  // title - short title of the role
  // detail (optional) - more text to describe the role
  // start - datetime/timestamp of starting time
  // end - datetime/timestamp of finishing time
  // for_guests - bool to signigfy whether to show to guests or not
  // id - DateTime creation (DateTime.now().millisecondsSinceEpoch) int of the role
  // ! NOTE: start is optional, but if it exists then end must also be a thing
  final List<Map<String, dynamic>> _roles = List.empty(growable: true);

  DateTime? _finishTime;
  bool _allDay = false, _online = false;
  String _address = '8A Princes Dr, Newtownabbey, BT37 0AZ, Northern Ireland',
      _mapLink = 'https://goo.gl/maps/ns21zf5F9KPxeKxn6';

  EventProgram();

  EventProgram.fromMap(Map<String, dynamic> data) {
    if (data['FinishTime'] != null) {
      _finishTime = (data['FinishTime'] as Timestamp).toDate();
    }
    _allDay = data['AllDay'];
    _online = data['Online'] ?? false;
    _address = data['Address'] ?? '8A Princes Dr, Newtownabbey, BT37 0AZ, Northern Ireland';
    _mapLink = data['MapLink'] ?? 'https://goo.gl/maps/ns21zf5F9KPxeKxn6';

    final List<Map<String, dynamic>> rawData = List<Map<String, dynamic>>.from(data['Roles']);
    for (final entry in rawData) {
      _roles.add({
        'uids': List<String>.from(entry['uids']),
        'detail': entry['detail'],
        'title': entry['title'],
        'start': entry['start'] != null ? (entry['start'] as Timestamp).toDate() : null,
        'end': entry['end'] != null ? (entry['end'] as Timestamp).toDate() : null,
        'for_guests': entry['for_guests'],
        'id': entry['id'] ?? DateTime.now().millisecondsSinceEpoch
      });
    }
  }

  toJson() {
    return {
      'AllDay': _allDay,
      'Online': _online,
      'Address': _address,
      'MapLink': _mapLink,
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
        'id': entry['id'],
      });
    }

    return result;
  }

  List<Map<String, dynamic>> get roles => UnmodifiableListView(_roles);
  bool get allDay => _allDay;
  bool get online => _online;
  String get address => _address;
  String get mapLink => _mapLink;
  DateTime? get finishTime => _finishTime;

  void setAllDay(final bool state) => _allDay = state;
  void setFinishTime(final DateTime? finish) => _finishTime = finish;
  void setOnline(final bool state) => _online = state;
  void setAddress(final String address) => _address = address;
  void setMapLink(final String newMapLink) => _mapLink = newMapLink;
  void orderProgramsByStartTime() =>
      _roles.sort(((a, b) => (a['start'] as DateTime).compareTo(b['start'] as DateTime)));
  void clearRoles() => _roles.clear();

  void addRole(
      {required List<String> uids,
      required String title,
      required DateTime? start,
      required DateTime? end,
      required int id,
      bool forGuests = true,
      int priority = 1,
      String detail = ''}) {
    _roles.add(<String, dynamic>{
      'uids': uids,
      'detail': detail,
      'title': title,
      'start': start,
      'end': end,
      'for_guests': forGuests,
      'id': id
    });
  }

  void removeRole(final int id) => _roles.removeWhere((entry) => entry['id'] == id);

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
