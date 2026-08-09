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

  EventProgram.fromMap(final Map<String, dynamic> data) {
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

  Map<String, Object?> toJson() {
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
        'start': entry['start'] == null ? null : Timestamp.fromDate(entry['start'] as DateTime),
        'end': entry['end'] == null ? null : Timestamp.fromDate(entry['end'] as DateTime),
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

  /// Roles whose start is at or after [threshold], optionally excluding one role.
  int countRolesStartingAtOrAfter(DateTime threshold, {int? excludeRoleId}) {
    return _roles.where((role) {
      if (excludeRoleId != null && role['id'] == excludeRoleId) return false;
      final start = role['start'] as DateTime?;
      return start != null && !start.isBefore(threshold);
    }).length;
  }

  /// Shifts start/end of roles with start >= [threshold] by [delta].
  void shiftRolesStartingAtOrAfter(DateTime threshold, Duration delta, {int? excludeRoleId}) {
    if (delta == Duration.zero) return;
    for (final role in _roles) {
      if (excludeRoleId != null && role['id'] == excludeRoleId) continue;
      final start = role['start'] as DateTime?;
      final end = role['end'] as DateTime?;
      if (start == null || end == null || start.isBefore(threshold)) continue;
      role['start'] = start.add(delta);
      role['end'] = end.add(delta);
    }
  }

  /// Moves every role onto [newDay]'s calendar date relative to [oldDay],
  /// preserving each role's clock time (and any overnight day offset).
  void rebaseRolesToCalendarDate({
    required DateTime oldDay,
    required DateTime newDay,
  }) {
    final oldDateOnly = DateTime(oldDay.year, oldDay.month, oldDay.day);
    final newDateOnly = DateTime(newDay.year, newDay.month, newDay.day);
    final delta = newDateOnly.difference(oldDateOnly);
    if (delta == Duration.zero) return;

    for (final role in _roles) {
      final start = role['start'] as DateTime?;
      final end = role['end'] as DateTime?;
      if (start != null) role['start'] = start.add(delta);
      if (end != null) role['end'] = end.add(delta);
    }
  }

  /// Updates one role's timing. When [shiftFollowing] is true, roles that started
  /// at or after the previous end are shifted by (newEnd - oldEnd), preserving gaps.
  void updateRoleTiming({
    required int roleId,
    required DateTime newStart,
    required DateTime newEnd,
    required bool shiftFollowing,
  }) {
    final role = _roles.firstWhere((entry) => entry['id'] == roleId);
    final DateTime oldEnd = role['end'] as DateTime;
    role['start'] = newStart;
    role['end'] = newEnd;
    if (shiftFollowing) {
      shiftRolesStartingAtOrAfter(oldEnd, newEnd.difference(oldEnd), excludeRoleId: roleId);
    }
    orderProgramsByStartTime();
  }

  /// When inserting a new item at [start]–[end], optionally push later items by its duration.
  void applyInsertShift({
    required DateTime start,
    required DateTime end,
    required bool shiftFollowing,
  }) {
    if (!shiftFollowing) return;
    shiftRolesStartingAtOrAfter(start, end.difference(start));
  }

  /// Moves a role one place earlier (-1) or later (+1) in start-time order.
  /// Swaps time slots with the neighbor while preserving each duration and the gap.
  /// Returns false if the move is not possible.
  bool moveRoleInOrder(int roleId, int direction) {
    if (direction != -1 && direction != 1) return false;
    orderProgramsByStartTime();
    final int index = _roles.indexWhere((entry) => entry['id'] == roleId);
    final int newIndex = index + direction;
    if (index < 0 || newIndex < 0 || newIndex >= _roles.length) return false;

    final int earlierIndex = index < newIndex ? index : newIndex;
    final int laterIndex = index < newIndex ? newIndex : index;
    final Map<String, dynamic> earlier = _roles[earlierIndex];
    final Map<String, dynamic> later = _roles[laterIndex];

    final DateTime earlierStart = earlier['start'] as DateTime;
    final DateTime earlierEnd = earlier['end'] as DateTime;
    final DateTime laterStart = later['start'] as DateTime;
    final DateTime laterEnd = later['end'] as DateTime;
    final Duration earlierDuration = earlierEnd.difference(earlierStart);
    final Duration laterDuration = laterEnd.difference(laterStart);
    final Duration gap = laterStart.difference(earlierEnd);

    // Neighbor takes the earlier slot; original earlier item follows with the same gap.
    final DateTime swappedEarlierStart = earlierStart;
    final DateTime swappedEarlierEnd = swappedEarlierStart.add(laterDuration);
    final DateTime swappedLaterStart = swappedEarlierEnd.add(gap);
    final DateTime swappedLaterEnd = swappedLaterStart.add(earlierDuration);

    earlier['start'] = swappedLaterStart;
    earlier['end'] = swappedLaterEnd;
    later['start'] = swappedEarlierStart;
    later['end'] = swappedEarlierEnd;

    orderProgramsByStartTime();
    return true;
  }

  /// Sorted index of [roleId], or -1 if missing / missing start.
  int indexOfRole(int roleId) {
    orderProgramsByStartTime();
    return _roles.indexWhere((entry) => entry['id'] == roleId);
  }

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
