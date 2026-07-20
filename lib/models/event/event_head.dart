import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EventHead {
  late final String _id;
  late final List<Map<String, dynamic>> _media;
  late String _title, _subtitle, _location;
  late DateTime _recentDate;
  DateTime? _eventDate;
  late int _interestedCount, _attendeeCount;

  EventHead({
    required String id,
    String title = '',
    String subtitle = '',
    String location = 'Belfast',
  }) {
    _id = id;
    _title = title;
    _subtitle = subtitle;
    _location = location;
    _media = List<Map<String, dynamic>>.empty(growable: true);
    _recentDate = DateTime.now();
    _interestedCount = 0;
    _attendeeCount = 0;
  }

  EventHead.fromMap(String id, Map<String, dynamic> data) {
    _id = id;
    _title = data['Title'];
    _subtitle = data['Subtitle'];
    _location = data['Location'];
    _media = _toMedia(List.from(data['Media']));
    _recentDate = (data['RecentDate'] as Timestamp).toDate();
    _eventDate = data['EventDate'] == null ? null : (data['EventDate'] as Timestamp).toDate();
    _interestedCount = (data['InterestedCount'] as num?)?.toInt() ?? 0;
    _attendeeCount = (data['AttendeeCount'] as num?)?.toInt() ?? 0;
  }

  List<Map<String, dynamic>> _toMedia(List<Map<String, dynamic>> data) {
    final List<Map<String, dynamic>> result = List<Map<String, dynamic>>.empty(growable: true);
    for (final entry in data) {
      result.add(
          {'src': entry['src'], 'type': entry['type'], 'title': entry['title'], 'thumbnailSrc': entry['thumbnailSrc']});
    }
    return result;
  }

  Map<String, Object?> toJson() {
    return {
      'ID': _id,
      'Title': _title,
      'Subtitle': _subtitle,
      'Location': _location,
      'Media': _media,
      'RecentDate': Timestamp.fromDate(_recentDate),
      'EventDate': _eventDate == null ? null : Timestamp.fromDate(_eventDate!),
      'InterestedCount': _interestedCount,
      'AttendeeCount': _attendeeCount,
    };
  }

  String get id => _id;
  String get title => _title;
  String get subtitle => _subtitle;
  String get location => _location;
  DateTime get recentDate => _recentDate;
  DateTime? get eventDate => _eventDate;
  int get interestedCount => _interestedCount;
  int get attendeeCount => _attendeeCount;
  bool get hasAttendanceCounts => _interestedCount > 0 || _attendeeCount > 0;
  TimeOfDay get startTimeOfEvent => TimeOfDay.fromDateTime(_eventDate!);
  List<Map<String, dynamic>> get media => UnmodifiableListView(_media);

  String? getKeyGraphic() {
    for (final entry in media) {
      if (entry['type']!.compareTo('img') == 0) {
        return entry['src'];
      }
    }
    return null;
  }

  void setTitle(final String newTitle) => _title = newTitle;
  void setSubtitle(final String newSubtitle) => _subtitle = newSubtitle;
  void setRecentDate(final DateTime recentDate) => _recentDate = recentDate;
  void setEventDate(final DateTime? newEventDate) => _eventDate = newEventDate;
  void removeEventDate() => _eventDate = null;
  void setLocation(final String newLocation) => _location = newLocation;
  void setInterestedCount(final int count) => _interestedCount = count < 0 ? 0 : count;
  void setAttendeeCount(final int count) => _attendeeCount = count < 0 ? 0 : count;

  bool containsMediaItem(final String src) => _media.map<String>((e) => e['src']!).toList().contains(src);
  void addMediaItem({required String type, required String src, String title = '', String thumbnail = ''}) {
    final Map<String, dynamic> item =
        Map<String, dynamic>.from({'type': type, 'src': src, 'title': title, 'thumbnailSrc': null});
    _media.add(item);
  }

  void removeMediaItem(final Map<String, dynamic> thisEntry) => _media.remove(thisEntry);
  void resetMediaWithOriginal(List<Map<String, dynamic>> original) {
    _media.clear();
    _media.addAll(original);
  }

  void clearMedia() => _media.clear();

  // UI Helper Methods
  bool get isUpcoming => _eventDate != null && _eventDate!.isAfter(DateTime.now());
  bool get isRecent => _eventDate != null && _eventDate!.isBefore(DateTime.now());
  bool get hasEventDate => _eventDate != null;
  bool get hasMedia => _media.isNotEmpty;

  String get eventStatusText {
    if (_eventDate == null) return 'No date set';
    if (isUpcoming) return 'Upcoming';
    if (isRecent) return 'Recent';
    return 'Today';
  }

  Color get eventStatusColor {
    if (_eventDate == null) return Colors.grey;
    if (isUpcoming) return Colors.green;
    if (isRecent) return Colors.orange;
    return Colors.blue;
  }

  Duration? get timeUntilEvent {
    if (_eventDate == null) return null;
    return _eventDate!.difference(DateTime.now());
  }

  String get formattedTimeUntilEvent {
    final duration = timeUntilEvent;
    if (duration == null) return '';

    if (duration.isNegative) {
      final absD = duration.abs();
      if (absD.inDays > 0) return '${absD.inDays} days ago';
      if (absD.inHours > 0) return '${absD.inHours} hours ago';
      return '${absD.inMinutes} minutes ago';
    } else {
      if (duration.inDays > 0) return 'In ${duration.inDays} days';
      if (duration.inHours > 0) return 'In ${duration.inHours} hours';
      return 'In ${duration.inMinutes} minutes';
    }
  }

  int get mediaCount => _media.length;
  int get imageCount => _media.where((m) => m['type'] == 'img').length;
  int get videoCount => _media.where((m) => m['type'] == 'video').length;
}
