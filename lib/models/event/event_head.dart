import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';

class EventHead {
  late final String _location, _id;
  late final Map<String, String> _media;
  late String _title, _subtitle;
  late DateTime _recentDate;
  DateTime? _eventDate;

  EventHead({
    required id,
    required Map<String, String> media,
    String title = '',
    String subtitle = '',
    String location = 'Belfast',
  }) {
    _id = id;
    _media = media;
    _title = title;
    _subtitle = subtitle;
    _location = location;
    _recentDate = DateTime.now();
  }

  EventHead.fromMap(String id, Map<String, dynamic> data)
      : _id = id,
        _title = data['Title'],
        _subtitle = data['Subtitle'],
        _location = data['Location'],
        _media = Map.from(data['Media']),
        _recentDate = (data['RecentDate'] as Timestamp).toDate(),
        _eventDate = (data['EventDate'] as Timestamp).toDate(); // TODO will this break if null?

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
  Map<String, String> get media => UnmodifiableMapView(_media);

  void setTitle(String newTitle) => _title = newTitle;
  void setSubtitle(String newSubtitle) => _subtitle = newSubtitle;
  void setRecentDate(DateTime recentDate) => _recentDate = recentDate;
  void setEventDate(DateTime newEventDate) => _eventDate = eventDate;
  void setMediaFile(String src, String type) => _media[src] = type;
  void removeMediaFile(String src) => _media.remove(src);
}
