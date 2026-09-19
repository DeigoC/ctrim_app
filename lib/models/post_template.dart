import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'event/event_program.dart';

/// Hardcoded grouping for post templates (Services vs Cell Groups).
enum PostTemplateCategory {
  service('service', 'Services'),
  cellGroup('cellGroup', 'Cell Groups');

  const PostTemplateCategory(this.firestoreValue, this.label);

  final String firestoreValue;
  final String label;

  /// Section order on template picker screens (Cell Groups before Services).
  static const List<PostTemplateCategory> displayOrder = [
    cellGroup,
    service,
  ];

  static PostTemplateCategory fromFirestore(final dynamic rawValue) {
    final value = (rawValue ?? '').toString().trim().toLowerCase();
    if (value == cellGroup.firestoreValue.toLowerCase()) {
      return cellGroup;
    }
    // Missing / unknown values default to Services so existing records
    // stay in the first section without a data migration.
    return service;
  }
}

/// Named programme variant on a [PostTemplate] (people, tags, slot times).
class SchedulePreset {
  static const String defaultId = 'default';
  static const String defaultName = 'Default';

  late String _id, _name;
  DateTime? _startTime, _finishTime;
  late List<Map<String, dynamic>> _roles;

  SchedulePreset({
    required String id,
    required String name,
    DateTime? startTime,
    DateTime? finishTime,
    List<Map<String, dynamic>>? roles,
  }) {
    _id = id;
    _name = name;
    _startTime = startTime;
    _finishTime = finishTime;
    _roles = roles == null
        ? <Map<String, dynamic>>[]
        : roles.map(_copyRole).toList();
  }

  SchedulePreset.emptyDefault() : this(id: defaultId, name: defaultName);

  SchedulePreset.fromMap(final bool forLocal, final Map<String, dynamic> data) {
    _id = (data['id'] as String?)?.trim().isNotEmpty == true
        ? data['id'] as String
        : defaultId;
    _name = (data['name'] as String?)?.trim().isNotEmpty == true
        ? data['name'] as String
        : defaultName;
    _startTime = _parseDateTime(forLocal, data['startTime']);
    _finishTime = _parseDateTime(forLocal, data['finishTime']);
    _roles =
        parseRoles(forLocal, PostTemplate.asStringKeyedMapList(data['roles']));
  }

  Map<String, dynamic> toJson(final bool forLocal) {
    return {
      'id': _id,
      'name': _name,
      'startTime': _dateTimeToJson(forLocal, _startTime),
      'finishTime': _dateTimeToJson(forLocal, _finishTime),
      'roles': rolesToJson(forLocal, _roles),
    };
  }

  String get id => _id;
  String get name => _name;
  DateTime? get startTime => _startTime;
  DateTime? get finishTime => _finishTime;
  List<Map<String, dynamic>> get roles => _roles;

  void setName(final String name) => _name = name;
  void setStartTime(final DateTime? start) => _startTime = start;
  void setFinishTime(final DateTime? finish) => _finishTime = finish;
  void setRoles(final List<Map<String, dynamic>> roles) =>
      _roles = roles.map(_copyRole).toList();

  SchedulePreset copy({String? id, String? name}) {
    return SchedulePreset(
      id: id ?? _id,
      name: name ?? _name,
      startTime: _startTime,
      finishTime: _finishTime,
      roles: _roles,
    );
  }

  static String newId() => DateTime.now().millisecondsSinceEpoch.toString();

  static List<String> assignedUserIdsOf(final SchedulePreset preset) {
    final ids = <String>{};
    for (final role in preset.roles) {
      ids.addAll(List<String>.from(role['uids'] ?? const []));
    }
    return ids.toList();
  }

  static List<Map<String, dynamic>> parseRoles(
      final bool forLocal, final List<Map<String, dynamic>> rawData) {
    final List<Map<String, dynamic>> result = List.empty(growable: true);
    for (final entry in rawData) {
      result.add({
        'uids': List<String>.from(entry['uids'] ?? const []),
        'detail': entry['detail'],
        'title': entry['title'],
        'start': _parseDateTime(forLocal, entry['start']),
        'end': _parseDateTime(forLocal, entry['end']),
        'for_guests': entry['for_guests'],
        'id': entry['id'] ?? DateTime.now().millisecondsSinceEpoch,
        'tagIDs': EventProgram.tagIDsOf(entry),
      });
    }
    return result;
  }

  static List<Map<String, dynamic>> rolesToJson(
      final bool forLocal, final List<Map<String, dynamic>> roles) {
    final List<Map<String, dynamic>> result =
        List<Map<String, dynamic>>.empty(growable: true);
    for (final entry in roles) {
      result.add({
        'uids': entry['uids'],
        'detail': entry['detail'],
        'title': entry['title'],
        'start': _dateTimeToJson(forLocal, entry['start'] as DateTime?),
        'end': _dateTimeToJson(forLocal, entry['end'] as DateTime?),
        'for_guests': entry['for_guests'],
        'id': entry['id'],
        'tagIDs': EventProgram.tagIDsOf(entry),
      });
    }
    return result;
  }

  static Map<String, dynamic> _copyRole(final Map<String, dynamic> role) {
    return {
      'uids': List<String>.from(role['uids'] ?? const []),
      'detail': role['detail'],
      'title': role['title'],
      'start': role['start'],
      'end': role['end'],
      'for_guests': role['for_guests'],
      'id': role['id'],
      'tagIDs': EventProgram.tagIDsOf(role),
    };
  }

  static DateTime? _parseDateTime(final bool forLocal, final dynamic raw) {
    if (raw == null) return null;
    if (forLocal) {
      if (raw is DateTime) return raw;
      return DateTime.fromMillisecondsSinceEpoch(raw as int);
    }
    if (raw is Timestamp) return raw.toDate();
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    if (raw is DateTime) return raw;
    return null;
  }

  static dynamic _dateTimeToJson(final bool forLocal, final DateTime? value) {
    if (value == null) return null;
    return forLocal ? value.millisecondsSinceEpoch : Timestamp.fromDate(value);
  }
}

class PostTemplate {
  late String _id, _title, _description, _headTitle, _body, _location;
  PostTemplateCategory _category = PostTemplateCategory.service;
  late List<String> _topics,
      _tagIDs,
      _cellGroupIDs,
      _expectedAttendeeUserIDs,
      _contributorUIDs,
      _subtitles;
  late List<Map<String, dynamic>> _headMedia,
      _media,
      _headMediaPool,
      _bodyMediaPool;
  late List<Map<String, dynamic>> _logs;
  String? _leadSpeakerUID;
  bool _isPeriodParent = false;

  // * Event Program related
  late DateTime? _startTime, _finishTime;
  late String _mapLink, _address;
  late List<Map<String, dynamic>> _roles;
  late List<SchedulePreset> _schedulePresets;
  bool _allDay = false, _online = false;
  int? _defaultDayOfWeek;

  PostTemplate.fromMap(
      final bool forLocal, final String id, final Map<String, dynamic> data) {
    _id = id;

    // head - meta related
    _title = data['Title'];
    _description = data['Description'];
    _headTitle = data['HeadTitle'];
    _topics = List.from(data['Topics']);
    _tagIDs =
        data['TagIDs'] != null ? List<String>.from(data['TagIDs']) : <String>[];
    _cellGroupIDs = data['CellGroupIDs'] != null
        ? List<String>.from(data['CellGroupIDs'])
        : <String>[];
    _expectedAttendeeUserIDs = data['ExpectedAttendeeUserIDs'] != null
        ? List<String>.from(data['ExpectedAttendeeUserIDs'])
        : <String>[];
    _contributorUIDs = List.from(data['Contributors']);
    _subtitles = data['Subtitles'] != null
        ? List<String>.from(data['Subtitles'])
        : <String>[];
    _location = data['Location'];
    _category = PostTemplateCategory.fromFirestore(data['Category']);
    _leadSpeakerUID = data['LeadSpeakerUID'] as String?;
    _isPeriodParent = data['IsPeriodParent'] == true;

    // body
    _body = data['Body'];

    // program related
    _allDay = data['AllDay'];
    _online = data['Online'];
    _address = data['Address'];
    _mapLink = data['MapLink'];
    final topLevelRoles = SchedulePreset.parseRoles(
        forLocal, asStringKeyedMapList(data['Roles']));
    _startTime = SchedulePreset._parseDateTime(forLocal, data['StartTime']);
    _finishTime = SchedulePreset._parseDateTime(forLocal, data['FinishTime']);
    _roles = topLevelRoles;
    _schedulePresets = _parseSchedulePresets(
      forLocal,
      data['SchedulePresets'],
      topLevelRoles: topLevelRoles,
      startTime: _startTime,
      finishTime: _finishTime,
    );
    _mirrorFirstPresetToTopLevel();

    // media — nested Hive/JSON maps are often Map<dynamic, dynamic>
    _headMedia = _parseMedia(asStringKeyedMapList(data['HeadMedia']));
    _media = _parseMedia(asStringKeyedMapList(data['Media']));
    _headMediaPool = data['HeadMediaPool'] != null
        ? _parseMedia(asStringKeyedMapList(data['HeadMediaPool']))
        : <Map<String, dynamic>>[];
    _bodyMediaPool = data['BodyMediaPool'] != null
        ? _parseMedia(asStringKeyedMapList(data['BodyMediaPool']))
        : <Map<String, dynamic>>[];
    _defaultDayOfWeek = data['DefaultDayOfWeek'] != null
        ? data['DefaultDayOfWeek'] as int?
        : null;
    _logs = _parseLogs(forLocal, data['Logs']);
  }

  Map<String, dynamic> toJson(final bool forLocal) {
    _mirrorFirstPresetToTopLevel();
    return {
      'Title': _title,
      'Description': _description,
      'HeadTitle': _headTitle,
      'Body': _body,
      'Location': _location,
      'Category': _category.firestoreValue,
      'Topics': _topics,
      'TagIDs': _tagIDs,
      'CellGroupIDs': _cellGroupIDs,
      'ExpectedAttendeeUserIDs': _expectedAttendeeUserIDs,
      'Contributors': _contributorUIDs,
      'LeadSpeakerUID': _leadSpeakerUID,
      'IsPeriodParent': _isPeriodParent,
      'Subtitles': _subtitles,
      'AllDay': _allDay,
      'Online': _online,
      'Address': _address,
      'MapLink': _mapLink,
      'HeadMedia': _headMedia,
      'Media': _media,
      'HeadMediaPool': _headMediaPool,
      'BodyMediaPool': _bodyMediaPool,
      'DefaultDayOfWeek': _defaultDayOfWeek,
      'StartTime': SchedulePreset._dateTimeToJson(forLocal, _startTime),
      'FinishTime': SchedulePreset._dateTimeToJson(forLocal, _finishTime),
      'Roles': SchedulePreset.rolesToJson(forLocal, _roles),
      'SchedulePresets':
          _schedulePresets.map((preset) => preset.toJson(forLocal)).toList(),
      'Logs': _logsToJson(forLocal),
    };
  }

  // getters
  String get id => _id;
  String get title => _title;
  String get description => _description;
  String get headTitle => _headTitle;
  String get body => _body;
  String get location => _location;
  PostTemplateCategory get category => _category;
  String get mapLink => _mapLink;
  String get address => _address;
  bool get allDay => _allDay;
  bool get online => _online;

  DateTime? get startTime =>
      _schedulePresets.isEmpty ? _startTime : _schedulePresets.first.startTime;
  DateTime? get finishTime => _schedulePresets.isEmpty
      ? _finishTime
      : _schedulePresets.first.finishTime;
  int? get defaultDayOfWeek => _defaultDayOfWeek;

  List<Map<String, dynamic>> get headMedia => _headMedia;
  List<Map<String, dynamic>> get media => _media;
  List<Map<String, dynamic>> get headMediaPool => _headMediaPool;
  List<Map<String, dynamic>> get bodyMediaPool => _bodyMediaPool;

  /// Cover / key-graphic candidates. Prefer [bodyMediaPool] (the intended cover pool);
  /// fall back to [headMediaPool] for older templates.
  List<Map<String, dynamic>> get keyGraphicPool =>
      _bodyMediaPool.isNotEmpty ? _bodyMediaPool : _headMediaPool;
  List<Map<String, dynamic>> get roles =>
      _schedulePresets.isEmpty ? _roles : _schedulePresets.first.roles;
  List<SchedulePreset> get schedulePresets =>
      UnmodifiableListView(_schedulePresets);
  List<String> get contributors => _contributorUIDs;
  List<String> get topics => _topics;
  List<String> get tagIDs => UnmodifiableListView(_tagIDs);
  List<String> get cellGroupIDs => UnmodifiableListView(_cellGroupIDs);
  List<String> get expectedAttendeeUserIDs =>
      UnmodifiableListView(_expectedAttendeeUserIDs);
  List<String> get subtitles => _subtitles;
  String? get leadSpeakerUID => _leadSpeakerUID;
  bool get isPeriodParent => _isPeriodParent;

  /// Change history entries: `{uid, log, ts}` — newest first after [addLog].
  List<Map<String, dynamic>> get logs => UnmodifiableListView(_logs);

  void setTagIDs(final List<String> tagIDs) =>
      _tagIDs = List<String>.from(tagIDs);
  void setCellGroupIDs(final List<String> cellGroupIDs) =>
      _cellGroupIDs = List<String>.from(cellGroupIDs);

  void setExpectedAttendeeUserIDs(final List<String> userIds) =>
      _expectedAttendeeUserIDs = List<String>.from(userIds);

  SchedulePreset? presetById(final String id) {
    for (final preset in _schedulePresets) {
      if (preset.id == id) return preset;
    }
    return null;
  }

  void setSchedulePresets(final List<SchedulePreset> presets) {
    _schedulePresets = presets.map((preset) => preset.copy()).toList();
    _mirrorFirstPresetToTopLevel();
  }

  /// Prepends a change-history entry (same shape as post [EventLog] entries).
  void addLog(
          {required String log, required String uid, required DateTime ts}) =>
      _logs.insert(0, {'log': log, 'uid': uid, 'ts': ts});

  void setLogs(final List<Map<String, dynamic>> logs) =>
      _logs = logs.map((e) => Map<String, dynamic>.from(e)).toList();

  // setters
  void setTitle(final String title) => _title = title;
  void setDescription(final String description) => _description = description;
  void setHeadTitle(final String headTitle) => _headTitle = headTitle;
  void setBody(final String body) => _body = body;
  void setAllDay(final bool newState) => _allDay = newState;
  void setOnline(final bool newState) => _online = newState;
  void setMapLink(final String mapLink) => _mapLink = mapLink;
  void setAddress(final String address) => _address = address;
  void setLeadSpeakerUID(final String? uid) => _leadSpeakerUID = uid;
  void setIsPeriodParent(final bool value) => _isPeriodParent = value;
  void setCategory(final PostTemplateCategory value) => _category = value;

  void setStartTime(final DateTime? start) {
    _startTime = start;
    if (_schedulePresets.isNotEmpty) {
      _schedulePresets.first.setStartTime(start);
    }
  }

  void setEndtime(final DateTime? end) {
    _finishTime = end;
    if (_schedulePresets.isNotEmpty) {
      _schedulePresets.first.setFinishTime(end);
    }
  }

  void setDefaultDayOfWeek(final int? day) => _defaultDayOfWeek = day;

  // subtitle list management
  void addSubtitle(final String subtitle) {
    if (!_subtitles.contains(subtitle)) {
      _subtitles.add(subtitle);
    }
  }

  void removeSubtitle(final String subtitle) => _subtitles.remove(subtitle);

  void setSubtitles(final List<String> subtitles) =>
      _subtitles = List<String>.from(subtitles);

  String? getRandomSubtitle() {
    if (_subtitles.isEmpty) return null;
    final random = DateTime.now().millisecondsSinceEpoch % _subtitles.length;
    return _subtitles[random];
  }

  // head media pool management
  void addHeadMediaPoolItem(final Map<String, dynamic> item) {
    if (!_headMediaPool.any((e) => e['src'] == item['src'])) {
      _headMediaPool.add(Map<String, dynamic>.from(item));
    }
  }

  void removeHeadMediaPoolItem(final String src) =>
      _headMediaPool.removeWhere((e) => e['src'] == src);

  void setHeadMediaPool(final List<Map<String, dynamic>> pool) =>
      _headMediaPool = pool.map((e) => Map<String, dynamic>.from(e)).toList();

  Map<String, dynamic>? getRandomHeadMediaPoolItem() {
    if (_headMediaPool.isEmpty) return null;
    final index = DateTime.now().millisecondsSinceEpoch % _headMediaPool.length;
    return _headMediaPool[index];
  }

  // body media pool management
  void addBodyMediaPoolItem(final Map<String, dynamic> item) {
    if (!_bodyMediaPool.any((e) => e['src'] == item['src'])) {
      _bodyMediaPool.add(Map<String, dynamic>.from(item));
    }
  }

  void removeBodyMediaPoolItem(final String src) =>
      _bodyMediaPool.removeWhere((e) => e['src'] == src);

  void setBodyMediaPool(final List<Map<String, dynamic>> pool) =>
      _bodyMediaPool = pool.map((e) => Map<String, dynamic>.from(e)).toList();

  Map<String, dynamic>? getRandomBodyMediaPoolItem() {
    if (_bodyMediaPool.isEmpty) return null;
    final index = DateTime.now().millisecondsSinceEpoch % _bodyMediaPool.length;
    return _bodyMediaPool[index];
  }

  Map<String, dynamic>? getRandomKeyGraphicPoolItem() {
    final pool = keyGraphicPool;
    if (pool.isEmpty) return null;
    final index = DateTime.now().millisecondsSinceEpoch % pool.length;
    return Map<String, dynamic>.from(pool[index]);
  }

  // private methods

  /// Hive (and some JSON paths) yield [Map]<dynamic, dynamic>; cast each entry.
  static List<Map<String, dynamic>> asStringKeyedMapList(final dynamic raw) {
    if (raw == null) return <Map<String, dynamic>>[];
    return (raw as List)
        .map((entry) => Map<String, dynamic>.from(entry as Map))
        .toList();
  }

  void _mirrorFirstPresetToTopLevel() {
    if (_schedulePresets.isEmpty) {
      _startTime = null;
      _finishTime = null;
      _roles = <Map<String, dynamic>>[];
      return;
    }
    final first = _schedulePresets.first;
    _startTime = first.startTime;
    _finishTime = first.finishTime;
    _roles = first.roles;
  }

  static List<SchedulePreset> _parseSchedulePresets(
    final bool forLocal,
    final dynamic raw, {
    required List<Map<String, dynamic>> topLevelRoles,
    required DateTime? startTime,
    required DateTime? finishTime,
  }) {
    final parsed = asStringKeyedMapList(raw)
        .map((entry) => SchedulePreset.fromMap(forLocal, entry))
        .toList();
    if (parsed.isNotEmpty) return parsed;
    if (topLevelRoles.isEmpty && startTime == null && finishTime == null) {
      return <SchedulePreset>[];
    }
    return [
      SchedulePreset(
        id: SchedulePreset.defaultId,
        name: SchedulePreset.defaultName,
        startTime: startTime,
        finishTime: finishTime,
        roles: topLevelRoles,
      ),
    ];
  }

  List<Map<String, dynamic>> _parseMedia(
      final List<Map<String, dynamic>> data) {
    final List<Map<String, dynamic>> results =
        List<Map<String, dynamic>>.empty(growable: true);

    for (final entry in data) {
      results.add({
        'title': entry['title'],
        'src': entry['src'],
        'type': entry['type'],
        'thumbnailSrc': entry['thumbnailSrc']
      });
    }

    return results;
  }

  List<Map<String, dynamic>> _parseLogs(
      final bool forLocal, final dynamic raw) {
    if (raw == null) return <Map<String, dynamic>>[];
    final List<Map<String, dynamic>> result = <Map<String, dynamic>>[];
    for (final entry in asStringKeyedMapList(raw)) {
      final dynamic rawTs = entry['ts'];
      late final DateTime ts;
      if (forLocal) {
        ts = DateTime.fromMillisecondsSinceEpoch(rawTs as int);
      } else if (rawTs is Timestamp) {
        ts = rawTs.toDate();
      } else if (rawTs is int) {
        // Defensive: some paths may already store epoch ms remotely.
        ts = DateTime.fromMillisecondsSinceEpoch(rawTs);
      } else {
        continue;
      }
      result.add({
        'uid': entry['uid'] as String? ?? '',
        'log': entry['log'] as String? ?? '',
        'ts': ts,
      });
    }
    return result;
  }

  List<Map<String, dynamic>> _logsToJson(final bool forLocal) {
    final List<Map<String, dynamic>> result = <Map<String, dynamic>>[];
    for (final entry in _logs) {
      final DateTime ts = entry['ts'] as DateTime;
      result.add({
        'uid': entry['uid'],
        'log': entry['log'],
        'ts': forLocal ? ts.millisecondsSinceEpoch : Timestamp.fromDate(ts),
      });
    }
    return result;
  }
}
