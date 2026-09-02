import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';

/// How the rest of the schedule reacts when one role is moved.
enum ProgramShiftMode {
  /// Later items follow the move, keeping the run sheet sequential.
  cascade,

  /// Only the moved item changes; overlaps are allowed.
  parallel,
}

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

  /// Changes when any role timing changes — use to bust schedule tab caches.
  String get scheduleLayoutSignature => roles
      .map((final role) {
        final start = role['start'] as DateTime?;
        final end = role['end'] as DateTime?;
        return '${role['id']}:${start?.millisecondsSinceEpoch}:'
            '${end?.millisecondsSinceEpoch}';
      })
      .join('|');

  bool get allDay => _allDay;
  bool get online => _online;
  String get address => _address;
  String get mapLink => _mapLink;
  DateTime? get finishTime => _finishTime;

  /// URL opened by the Maps / Join action on the program schedule card.
  String get locationLaunchUrl => _online ? _address : _mapLink;

  bool get hasLocationLaunchUrl => locationLaunchUrl.trim().isNotEmpty;

  void setAllDay(final bool state) => _allDay = state;
  void setFinishTime(final DateTime? finish) => _finishTime = finish;
  void setOnline(final bool state) => _online = state;
  void setAddress(final String address) => _address = address;
  void setMapLink(final String newMapLink) => _mapLink = newMapLink;
  /// Sorts by start time, keeping roles that have no start at the end.
  void orderProgramsByStartTime() {
    _roles.sort((a, b) {
      final aStart = a['start'] as DateTime?;
      final bStart = b['start'] as DateTime?;
      if (aStart == null) return bStart == null ? 0 : 1;
      if (bStart == null) return -1;
      return aStart.compareTo(bStart);
    });
  }
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

  /// Drops a role onto [newStart], keeping its duration.
  ///
  /// [ProgramShiftMode.parallel] moves only this role, so it may overlap
  /// whatever else is running. [ProgramShiftMode.cascade] pushes the items it
  /// lands on later, passing the push down the chain until there is room; items
  /// that already started before the drop are left where they are.
  ///
  /// Returns false when the role is missing, untimed, or has not moved.
  bool moveRoleToStart({
    required int roleId,
    required DateTime newStart,
    required ProgramShiftMode mode,
  }) {
    final int index = _roles.indexWhere((entry) => entry['id'] == roleId);
    if (index < 0) return false;

    final role = _roles[index];
    final DateTime? oldStart = role['start'] as DateTime?;
    final DateTime? oldEnd = role['end'] as DateTime?;
    if (oldStart == null || oldEnd == null) return false;
    if (newStart.isAtSameMomentAs(oldStart)) return false;

    role['start'] = newStart;
    role['end'] = newStart.add(oldEnd.difference(oldStart));
    if (mode == ProgramShiftMode.cascade) {
      _pushCollidingRolesLater(roleId);
    }
    orderProgramsByStartTime();
    return true;
  }

  /// Walks forward from [roleId] pushing each overlapping role just far enough
  /// to clear the one before it. Stops at the first role that already fits.
  ///
  /// Roles that began before the drop point keep their times, so a long
  /// parallel item running underneath the schedule is never dragged along.
  void _pushCollidingRolesLater(final int roleId) {
    final int index = _roles.indexWhere((entry) => entry['id'] == roleId);
    if (index < 0) return;

    final DateTime movedStart = _roles[index]['start'] as DateTime;
    DateTime cursor = _roles[index]['end'] as DateTime;

    final following = _roles.where((entry) {
      if (entry['id'] == roleId) return false;
      final start = entry['start'] as DateTime?;
      return start != null &&
          entry['end'] != null &&
          !start.isBefore(movedStart);
    }).toList()
      ..sort((a, b) =>
          (a['start'] as DateTime).compareTo(b['start'] as DateTime));

    for (final entry in following) {
      final DateTime start = entry['start'] as DateTime;
      final DateTime end = entry['end'] as DateTime;
      if (!start.isBefore(cursor)) break;

      final Duration delta = cursor.difference(start);
      entry['start'] = start.add(delta);
      entry['end'] = end.add(delta);
      cursor = end.add(delta);
    }
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
