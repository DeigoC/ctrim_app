import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Self-serve interest entry. Stored under [EventAttendance.interested] keyed by authId.
class InterestedEntry {
  late final String _authId;
  late final String? _userId;
  late final String _displayName;
  late final DateTime _ts;

  InterestedEntry({
    required String authId,
    required String displayName,
    String? userId,
    DateTime? ts,
  }) {
    _authId = authId;
    _userId = userId;
    _displayName = displayName;
    _ts = ts ?? DateTime.now();
  }

  InterestedEntry.fromMap(String authId, Map<String, dynamic> data)
      : _authId = authId,
        _userId = data['userId'] as String?,
        _displayName = data['displayName'] as String? ?? 'Signed-in user',
        _ts = (data['ts'] as Timestamp).toDate();

  Map<String, Object?> toJson() {
    return {
      'userId': _userId,
      'displayName': _displayName,
      'ts': Timestamp.fromDate(_ts),
    };
  }

  String get authId => _authId;
  String? get userId => _userId;
  String get displayName => _displayName;
  DateTime get ts => _ts;
}

/// Staff-managed attendee: registered/placeholder user, or legacy free-text guest.
/// New guests should be added as placeholder users via [SelectUsersPage], not as externals.
class AttendeeEntry {
  static const String typeUser = 'user';
  static const String typeExternal = 'external';

  late final String _id;
  late final String _type;
  late final String? _userId;
  late final String? _name;
  late final String? _note;
  late final String _displayName;
  late final String _addedBy;
  late final DateTime _ts;

  AttendeeEntry.user({
    required String userId,
    required String displayName,
    required String addedBy,
    DateTime? ts,
  }) {
    _id = 'user_$userId';
    _type = typeUser;
    _userId = userId;
    _name = null;
    _note = null;
    _displayName = displayName;
    _addedBy = addedBy;
    _ts = ts ?? DateTime.now();
  }

  AttendeeEntry.external({
    required String name,
    required String addedBy,
    String? note,
    String? id,
    DateTime? ts,
  }) {
    _ts = ts ?? DateTime.now();
    _id = id ?? 'ext_${_ts.millisecondsSinceEpoch}';
    _type = typeExternal;
    _userId = null;
    _name = name;
    _note = note;
    _displayName = name;
    _addedBy = addedBy;
  }

  AttendeeEntry.fromMap(Map<String, dynamic> data)
      : _id = data['id'] as String,
        _type = data['type'] as String,
        _userId = data['userId'] as String?,
        _name = data['name'] as String?,
        _note = data['note'] as String?,
        _displayName = data['displayName'] as String? ??
            (data['name'] as String? ?? data['userId'] as String? ?? 'Attendee'),
        _addedBy = data['addedBy'] as String,
        _ts = (data['ts'] as Timestamp).toDate();

  Map<String, Object?> toJson() {
    return {
      'id': _id,
      'type': _type,
      'userId': _userId,
      'name': _name,
      'note': _note,
      'displayName': _displayName,
      'addedBy': _addedBy,
      'ts': Timestamp.fromDate(_ts),
    };
  }

  String get id => _id;
  String get type => _type;
  bool get isUser => _type == typeUser;
  bool get isExternal => _type == typeExternal;
  String? get userId => _userId;
  String? get name => _name;
  String? get note => _note;
  String get displayName => _displayName;
  String get addedBy => _addedBy;
  DateTime get ts => _ts;
}

/// Private supplemental doc: `events/{id}/supplemental/attendance`.
///
/// [interested] is a map keyed by Firebase Auth UID so rules can allow self-serve toggles.
/// [expectedUserIds] is the staff-managed “usual people” checklist for quick check-off
/// into [attendees] (e.g. recurring cell-group meetings).
class EventAttendance {
  late final Map<String, InterestedEntry> _interested;
  late final List<AttendeeEntry> _attendees;
  late final List<String> _expectedUserIds;

  EventAttendance({List<String> expectedUserIds = const []}) {
    _interested = <String, InterestedEntry>{};
    _attendees = List<AttendeeEntry>.empty(growable: true);
    _expectedUserIds = <String>[
      for (final id in expectedUserIds)
        if (id.isNotEmpty) id,
    ];
  }

  EventAttendance.fromMap(Map<String, dynamic> data) {
    _interested = <String, InterestedEntry>{};
    final rawInterested = data['interested'];
    if (rawInterested is Map) {
      rawInterested.forEach((key, value) {
        if (value is Map) {
          _interested[key.toString()] =
              InterestedEntry.fromMap(key.toString(), Map<String, dynamic>.from(value));
        }
      });
    }

    _attendees = List<AttendeeEntry>.empty(growable: true);
    final rawAttendees = data['attendees'];
    if (rawAttendees is List) {
      for (final entry in rawAttendees) {
        if (entry is Map) {
          _attendees.add(AttendeeEntry.fromMap(Map<String, dynamic>.from(entry)));
        }
      }
    }

    _expectedUserIds = List<String>.empty(growable: true);
    final rawExpected = data['expectedUserIds'] ?? data['ExpectedAttendeeUserIDs'];
    if (rawExpected is List) {
      for (final id in rawExpected) {
        if (id is String && id.isNotEmpty && !_expectedUserIds.contains(id)) {
          _expectedUserIds.add(id);
        }
      }
    }
  }

  Map<String, Object?> toJson() {
    return {
      'interested': {
        for (final e in _interested.entries) e.key: e.value.toJson(),
      },
      'attendees': _attendees.map((e) => e.toJson()).toList(),
      'expectedUserIds': List<String>.from(_expectedUserIds),
    };
  }

  Map<String, InterestedEntry> get interested => UnmodifiableMapView(_interested);
  List<AttendeeEntry> get attendees => UnmodifiableListView(_attendees);
  List<String> get expectedUserIds => UnmodifiableListView(_expectedUserIds);

  int get interestedCount => _interested.length;
  int get attendeeCount => _attendees.length;
  int get expectedCount => _expectedUserIds.length;

  bool hasInterest(String authId) => _interested.containsKey(authId);

  InterestedEntry? interestFor(String authId) => _interested[authId];

  void putInterest(InterestedEntry entry) => _interested[entry.authId] = entry;

  void removeInterest(String authId) => _interested.remove(authId);

  bool hasUserAttendee(String userId) =>
      _attendees.any((e) => e.isUser && e.userId == userId);

  bool hasExpectedUser(String userId) => _expectedUserIds.contains(userId);

  void setExpectedUserIds(List<String> userIds) {
    _expectedUserIds
      ..clear()
      ..addAll({for (final id in userIds) if (id.isNotEmpty) id});
  }

  void addAttendee(AttendeeEntry entry) {
    if (entry.isUser && entry.userId != null && hasUserAttendee(entry.userId!)) {
      return;
    }
    _attendees.add(entry);
  }

  void removeAttendeeById(String id) => _attendees.removeWhere((e) => e.id == id);

  /// Snapshot map used when replacing one list while preserving the others.
  Map<String, dynamic> toMutableMap() => {
        'interested': {
          for (final e in _interested.entries) e.key: e.value.toJson(),
        },
        'attendees': _attendees.map((e) => e.toJson()).toList(),
        'expectedUserIds': List<String>.from(_expectedUserIds),
      };
}
