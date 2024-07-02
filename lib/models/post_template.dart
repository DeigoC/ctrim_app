import 'package:cloud_firestore/cloud_firestore.dart';

class PostTemplate {
  late String _id, _title, _description, _headTitle, _body, _location;
  late List<String> _topics, _contributorUIDs;
  late List<Map<String, String>> _headMedia, _media;

  // * Event Program related
  late DateTime? _startTime, _finishTime;
  late String _mapLink, _address;
  late List<Map<String, dynamic>> _roles;
  bool _allDay = false, _online = false;

  PostTemplate.fromMap(final bool forLocal, final String id, final Map<String, dynamic> data) {
    _id = id;

    // head - meta related
    _title = data['Title'];
    _description = data['Description'];
    _headTitle = data['HeadTitle'];
    _topics = List.from(data['Topics']);
    _contributorUIDs = List.from(data['Contributors']);
    _location = data['Location'];

    // body
    _body = data['Body'];

    // program related
    _allDay = data['AllDay'];
    _online = data['Online'];
    _address = data['Address'];
    _mapLink = data['MapLink'];
    _roles = _parseRoles(forLocal, List<Map<String, dynamic>>.from(data['Roles']));
    if (data['StartTime'] != null) {
      if (forLocal) {
        _startTime = DateTime.fromMillisecondsSinceEpoch(data['StartTime']);
      } else {
        _startTime = (data['StartTime'] as Timestamp).toDate();
      }
    }
    if (data['FinishTime'] != null) {
      if (forLocal) {
        _finishTime = DateTime.fromMillisecondsSinceEpoch(data['FinishTime']);
      } else {
        _finishTime = (data['FinishTime'] as Timestamp).toDate();
      }
    }

    // media
    _headMedia = _parseMedia(List<Map<String, dynamic>>.from(data['HeadMedia']));
    _media = _parseMedia(List<Map<String, dynamic>>.from(data['Media']));
  }

  toJson(final bool forLocal) {
    dynamic startTime = _startTime;
    dynamic endTime = _finishTime;
    if (_startTime != null) {
      startTime = forLocal ? _startTime!.millisecondsSinceEpoch : Timestamp.fromDate(_startTime!);
    }
    if (_finishTime != null) {
      endTime = forLocal ? _finishTime!.millisecondsSinceEpoch : Timestamp.fromDate(_finishTime!);
    }

    return {
      'Title': _title,
      'Description': _description,
      'HeadTitle': _headTitle,
      'Body': _body,
      'Location': _location,
      'Topics': _topics,
      'Contributors': _contributorUIDs,
      'AllDay': _allDay,
      'Online': _online,
      'Address': _address,
      'MapLink': _mapLink,
      'HeadMedia': _headMedia,
      'Media': _media,
      'StartTime': startTime,
      'FinishTime': endTime,
      'Roles': _rolesToJson(forLocal),
    };
  }

  // getters
  String get id => _id;
  String get title => _title;
  String get description => _description;
  String get headTitle => _headTitle;
  String get body => _body;
  String get location => _location;
  String get mapLink => _mapLink;
  String get address => _address;
  bool get allDay => _allDay;
  bool get online => _online;

  DateTime? get startTime => _startTime;
  DateTime? get finishTime => _finishTime;

  List<Map<String, String>> get headMedia => _headMedia;
  List<Map<String, String>> get media => _media;
  List<Map<String, dynamic>> get roles => _roles;
  List<String> get contributors => _contributorUIDs;
  List<String> get topics => _topics;

  // setters
  void setTitle(final String title) => _title = title;
  void setDescription(final String description) => _description = description;
  void setHeadTitle(final String headTitle) => _headTitle = headTitle;
  void setBody(final String body) => _body = body;
  void setAllDay(final bool newState) => _allDay = newState;
  void setOnline(final bool newState) => _online = newState;
  void setMapLink(final String mapLink) => _mapLink = mapLink;
  void setAddress(final String address) => _address = address;

  void setStartTime(final DateTime? start) => _startTime = start;
  void setEndtime(final DateTime? end) => _finishTime = end;

  // private methods
  List<Map<String, dynamic>> _parseRoles(final bool forLocal, final List<Map<String, dynamic>> rawData) {
    final List<Map<String, dynamic>> result = List.empty(growable: true);
    for (final entry in rawData) {
      DateTime? start;
      DateTime? end;
      if (entry['start'] != null) {
        start = forLocal ? DateTime.fromMillisecondsSinceEpoch(entry['start']) : (entry['start'] as Timestamp).toDate();
      }
      if (entry['end'] != null) {
        end = forLocal ? DateTime.fromMillisecondsSinceEpoch(entry['end']) : (entry['end'] as Timestamp).toDate();
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

  List<Map<String, String>> _parseMedia(final List<Map<String, dynamic>> data) {
    final List<Map<String, String>> results = List<Map<String, String>>.empty(growable: true);

    for (final entry in data) {
      results.add({
        'title': entry['title'],
        'src': entry['src'],
        'type': entry['type'],
      });
    }

    return results;
  }

  List<Map<String, dynamic>> _rolesToJson(final bool forLocal) {
    final List<Map<String, dynamic>> result = List<Map<String, dynamic>>.empty(growable: true);
    for (final entry in _roles) {
      var start = entry['start'];
      var end = entry['end'];
      if (start != null) {
        start = forLocal ? (entry['start'] as DateTime).millisecondsSinceEpoch : Timestamp.fromDate(entry['start']);
      }
      if (end != null) {
        end = forLocal ? (entry['end'] as DateTime).millisecondsSinceEpoch : Timestamp.fromDate(entry['end']);
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
}
