import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EventHead {
  late final String _location, _id;
  late final List<Map<String, String>> _media;
  late String _title, _subtitle;
  late DateTime _recentDate;
  DateTime? _eventDate;

  EventHead({
    required id,
    String title = '',
    String subtitle = '',
    String location = 'Belfast',
  }) {
    _id = id;
    _title = title;
    _subtitle = subtitle;
    _location = location;
    _media = List<Map<String, String>>.empty(growable: true);
    _recentDate = DateTime.now();
  }

  EventHead.fromMap(String id, Map<String, dynamic> data) {
    _id = id;
    _title = data['Title'];
    _subtitle = data['Subtitle'];
    _location = data['Location'];
    _media = _toMedia(List.from(data['Media']));
    _recentDate = (data['RecentDate'] as Timestamp).toDate();
    _eventDate = data['EventDate'] == null ? null : (data['EventDate'] as Timestamp).toDate();
  }

  List<Map<String, String>> _toMedia(List<Map<String, dynamic>> data) {
    final List<Map<String, String>> result = List<Map<String, String>>.empty(growable: true);
    for (final entry in data) {
      result.add({'src': entry['src'], 'type': entry['type'], 'title': entry['title']});
    }
    return result;
  }

  toJson() {
    return {
      'Title': _title,
      'Subtitle': _subtitle,
      'Location': _location,
      'Media': _media,
      'RecentDate': Timestamp.fromDate(_recentDate),
      'EventDate': _eventDate == null ? null : Timestamp.fromDate(_eventDate!),
    };
  }

  String get id => _id;
  String get title => _title;
  String get subtitle => _subtitle;
  String get location => _location;
  DateTime get recentDate => _recentDate;
  DateTime? get eventDate => _eventDate;
  TimeOfDay get startTimeOfEvent => TimeOfDay.fromDateTime(_eventDate!);
  List<Map<String, String>> get media => _media; // unmodifiable?

  String? getKeyGraphic() {
    for (final entry in media) {
      if (entry['type']!.compareTo('img') == 0) {
        return entry['src'];
      }
    }
    return null;
  }

  void setTitle(String newTitle) => _title = newTitle;
  void setSubtitle(String newSubtitle) => _subtitle = newSubtitle;
  void setRecentDate(DateTime recentDate) => _recentDate = recentDate;
  void setEventDate(DateTime newEventDate) => _eventDate = eventDate;
}
