import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';

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
    _roles = _parseRoles(forLocal, _asStringKeyedMapList(data['Roles']));

    if (data['StartTime'] != null) {
      if (forLocal) {
        _startTime = DateTime.fromMillisecondsSinceEpoch(data['StartTime']);
      } else {
        _startTime = (data['StartTime'] as Timestamp).toDate();
      }
    } else {
      _startTime = null;
    }
    if (data['FinishTime'] != null) {
      if (forLocal) {
        _finishTime = DateTime.fromMillisecondsSinceEpoch(data['FinishTime']);
      } else {
        _finishTime = (data['FinishTime'] as Timestamp).toDate();
      }
    } else {
      _finishTime = null;
    }

    // media — nested Hive/JSON maps are often Map<dynamic, dynamic>
    _headMedia = _parseMedia(_asStringKeyedMapList(data['HeadMedia']));
    _media = _parseMedia(_asStringKeyedMapList(data['Media']));
    _headMediaPool = data['HeadMediaPool'] != null
        ? _parseMedia(_asStringKeyedMapList(data['HeadMediaPool']))
        : <Map<String, dynamic>>[];
    _bodyMediaPool = data['BodyMediaPool'] != null
        ? _parseMedia(_asStringKeyedMapList(data['BodyMediaPool']))
        : <Map<String, dynamic>>[];
    _defaultDayOfWeek = data['DefaultDayOfWeek'] != null
        ? data['DefaultDayOfWeek'] as int?
        : null;
    _logs = _parseLogs(forLocal, data['Logs']);
  }

  Map<String, dynamic> toJson(final bool forLocal) {
    dynamic startTime = _startTime;
    dynamic endTime = _finishTime;
    if (_startTime != null) {
      startTime = forLocal
          ? _startTime!.millisecondsSinceEpoch
          : Timestamp.fromDate(_startTime!);
    }
    if (_finishTime != null) {
      endTime = forLocal
          ? _finishTime!.millisecondsSinceEpoch
          : Timestamp.fromDate(_finishTime!);
    }

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
      'StartTime': startTime,
      'FinishTime': endTime,
      'Roles': _rolesToJson(forLocal),
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

  DateTime? get startTime => _startTime;
  DateTime? get finishTime => _finishTime;
  int? get defaultDayOfWeek => _defaultDayOfWeek;

  List<Map<String, dynamic>> get headMedia => _headMedia;
  List<Map<String, dynamic>> get media => _media;
  List<Map<String, dynamic>> get headMediaPool => _headMediaPool;
  List<Map<String, dynamic>> get bodyMediaPool => _bodyMediaPool;

  /// Cover / key-graphic candidates. Prefer [bodyMediaPool] (the intended cover pool);
  /// fall back to [headMediaPool] for older templates.
  List<Map<String, dynamic>> get keyGraphicPool =>
      _bodyMediaPool.isNotEmpty ? _bodyMediaPool : _headMediaPool;
  List<Map<String, dynamic>> get roles => _roles;
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

  void setStartTime(final DateTime? start) => _startTime = start;
  void setEndtime(final DateTime? end) => _finishTime = end;
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
  static List<Map<String, dynamic>> _asStringKeyedMapList(final dynamic raw) {
    if (raw == null) return <Map<String, dynamic>>[];
    return (raw as List)
        .map((entry) => Map<String, dynamic>.from(entry as Map))
        .toList();
  }

  List<Map<String, dynamic>> _parseRoles(
      final bool forLocal, final List<Map<String, dynamic>> rawData) {
    final List<Map<String, dynamic>> result = List.empty(growable: true);
    for (final entry in rawData) {
      DateTime? start;
      DateTime? end;
      if (entry['start'] != null) {
        start = forLocal
            ? DateTime.fromMillisecondsSinceEpoch(entry['start'])
            : (entry['start'] as Timestamp).toDate();
      }
      if (entry['end'] != null) {
        end = forLocal
            ? DateTime.fromMillisecondsSinceEpoch(entry['end'])
            : (entry['end'] as Timestamp).toDate();
      }

      result.add({
        'uids': List<String>.from(entry['uids']),
        'detail': entry['detail'],
        'title': entry['title'],
        'start': start,
        'end': end,
        'for_guests': entry['for_guests'],
        'id': entry['id'] ?? DateTime.now().millisecondsSinceEpoch
      });
    }

    return result;
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

  List<Map<String, dynamic>> _rolesToJson(final bool forLocal) {
    final List<Map<String, dynamic>> result =
        List<Map<String, dynamic>>.empty(growable: true);
    for (final entry in _roles) {
      var start = entry['start'];
      var end = entry['end'];
      if (start != null) {
        start = forLocal
            ? (entry['start'] as DateTime).millisecondsSinceEpoch
            : Timestamp.fromDate(entry['start']);
      }
      if (end != null) {
        end = forLocal
            ? (entry['end'] as DateTime).millisecondsSinceEpoch
            : Timestamp.fromDate(entry['end']);
      }

      result.add({
        'uids': entry['uids'],
        'detail': entry['detail'],
        'title': entry['title'],
        'start': start,
        'end': end,
        'for_guests': entry['for_guests'],
        'id': entry['id'],
      });
    }

    return result;
  }

  List<Map<String, dynamic>> _parseLogs(
      final bool forLocal, final dynamic raw) {
    if (raw == null) return <Map<String, dynamic>>[];
    final List<Map<String, dynamic>> result = <Map<String, dynamic>>[];
    for (final entry in _asStringKeyedMapList(raw)) {
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
