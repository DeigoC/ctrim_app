import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EventHead {
  late final String _id;
  late final List<Map<String, dynamic>> _media;
  late String _title, _subtitle, _location;
  late List<String> _tagIDs, _cellGroupIDs;
  late DateTime _recentDate;
  DateTime? _eventDate;
  late int _interestedCount, _attendeeCount;
  String? _leadSpeakerUID, _leadSpeakerImgSrc, _leadSpeakerName;
  bool _isPeriodParent = false;

  EventHead({
    required String id,
    String title = '',
    String subtitle = '',
    String location = 'Belfast',
    List<String> tagIDs = const [],
    List<String> cellGroupIDs = const [],
    bool isPeriodParent = false,
  }) {
    _id = id;
    _title = title;
    _subtitle = subtitle;
    _location = location;
    _tagIDs = List<String>.from(tagIDs);
    _cellGroupIDs = List<String>.from(cellGroupIDs);
    _isPeriodParent = isPeriodParent;
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
    _tagIDs = _parseTagIDs(data['TagIDs']);
    _cellGroupIDs = _parseTagIDs(data['CellGroupIDs']);
    _media = _toMedia(data['Media']);
    _recentDate = _parseDateTime(data['RecentDate']) ?? DateTime.now();
    _eventDate = _parseDateTime(data['EventDate']);
    _interestedCount = (data['InterestedCount'] as num?)?.toInt() ?? 0;
    _attendeeCount = (data['AttendeeCount'] as num?)?.toInt() ?? 0;
    _leadSpeakerUID = data['LeadSpeakerUID'] as String?;
    _leadSpeakerImgSrc = data['LeadSpeakerImgSrc'] as String?;
    _leadSpeakerName = data['LeadSpeakerName'] as String?;
    _isPeriodParent = data['IsPeriodParent'] == true;
  }

  static DateTime? _parseDateTime(final dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is num) return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    return null;
  }

  static List<String> _parseTagIDs(final dynamic raw) {
    if (raw is! List) return <String>[];
    return raw.map((e) => e.toString()).where((id) => id.isNotEmpty).toList();
  }

  List<Map<String, dynamic>> _toMedia(final dynamic raw) {
    if (raw is! List) {
      return List<Map<String, dynamic>>.empty(growable: true);
    }
    final List<Map<String, dynamic>> result = List<Map<String, dynamic>>.empty(growable: true);
    for (final entry in raw) {
      if (entry is! Map) continue;
      result.add({
        'src': entry['src'],
        'type': entry['type'],
        'title': entry['title'],
        'thumbnailSrc': entry['thumbnailSrc'],
      });
    }
    return result;
  }

  Map<String, Object?> toJson() {
    return {
      'ID': _id,
      'Title': _title,
      'Subtitle': _subtitle,
      'Location': _location,
      'TagIDs': _tagIDs,
      'CellGroupIDs': _cellGroupIDs,
      'Media': _media,
      'RecentDate': Timestamp.fromDate(_recentDate),
      'EventDate': _eventDate == null ? null : Timestamp.fromDate(_eventDate!),
      'InterestedCount': _interestedCount,
      'AttendeeCount': _attendeeCount,
      'LeadSpeakerUID': _leadSpeakerUID,
      'LeadSpeakerImgSrc': _leadSpeakerImgSrc,
      'LeadSpeakerName': _leadSpeakerName,
      'IsPeriodParent': _isPeriodParent,
    };
  }

  /// Hive-safe map: epoch millis instead of Firestore [Timestamp].
  Map<String, dynamic> toCacheJson() {
    return {
      'id': _id,
      'Title': _title,
      'Subtitle': _subtitle,
      'Location': _location,
      'TagIDs': _tagIDs,
      'CellGroupIDs': _cellGroupIDs,
      'Media': _media.map((e) => Map<String, dynamic>.from(e)).toList(),
      'RecentDate': _recentDate.millisecondsSinceEpoch,
      'EventDate': _eventDate?.millisecondsSinceEpoch,
      'InterestedCount': _interestedCount,
      'AttendeeCount': _attendeeCount,
      'LeadSpeakerUID': _leadSpeakerUID,
      'LeadSpeakerImgSrc': _leadSpeakerImgSrc,
      'LeadSpeakerName': _leadSpeakerName,
      'IsPeriodParent': _isPeriodParent,
    };
  }

  String get id => _id;
  String get title => _title;
  String get subtitle => _subtitle;
  String get location => _location;
  bool get isPeriodParent => _isPeriodParent;
  List<String> get tagIDs => UnmodifiableListView(_tagIDs);
  bool hasTag(final String tagId) => _tagIDs.contains(tagId);
  bool hasAnyTag(final Iterable<String> tagIds) => tagIds.any(_tagIDs.contains);
  List<String> get cellGroupIDs => UnmodifiableListView(_cellGroupIDs);
  bool hasCellGroup(final String cellGroupId) => _cellGroupIDs.contains(cellGroupId);
  DateTime get recentDate => _recentDate;
  DateTime? get eventDate => _eventDate;
  int get interestedCount => _interestedCount;
  int get attendeeCount => _attendeeCount;
  bool get hasAttendanceCounts => _interestedCount > 0 || _attendeeCount > 0;
  String? get leadSpeakerUID => _leadSpeakerUID;
  String? get leadSpeakerImgSrc => _leadSpeakerImgSrc;
  String? get leadSpeakerName => _leadSpeakerName;
  bool get hasLeadSpeaker => _leadSpeakerUID != null && _leadSpeakerUID!.isNotEmpty;
  bool get hasLeadSpeakerPortrait =>
      hasLeadSpeaker &&
      ((_leadSpeakerImgSrc != null && _leadSpeakerImgSrc!.isNotEmpty) ||
          (_leadSpeakerName != null && _leadSpeakerName!.isNotEmpty));
  TimeOfDay get startTimeOfEvent => TimeOfDay.fromDateTime(_eventDate!);
  List<Map<String, dynamic>> get media => UnmodifiableListView(_media);

  /// Cover image for AppBar / notifications / bulletin thumbnail.
  /// Prefers the first head media image; falls back to the lead speaker
  /// portrait only when no key-graphic images exist.
  String? getKeyGraphic() {
    for (final entry in media) {
      if (entry['type']!.compareTo('img') == 0) {
        return entry['src'];
      }
    }
    if (_leadSpeakerImgSrc != null && _leadSpeakerImgSrc!.isNotEmpty) {
      return _leadSpeakerImgSrc;
    }
    return null;
  }

  void setTitle(final String newTitle) => _title = newTitle;
  void setSubtitle(final String newSubtitle) => _subtitle = newSubtitle;
  void setRecentDate(final DateTime recentDate) => _recentDate = recentDate;
  void setEventDate(final DateTime? newEventDate) => _eventDate = newEventDate;
  void removeEventDate() => _eventDate = null;
  void setLocation(final String newLocation) => _location = newLocation;
  void setTagIDs(final List<String> tagIDs) => _tagIDs = List<String>.from(tagIDs);
  void setCellGroupIDs(final List<String> cellGroupIDs) =>
      _cellGroupIDs = List<String>.from(cellGroupIDs);
  void setIsPeriodParent(final bool value) => _isPeriodParent = value;
  void setInterestedCount(final int count) => _interestedCount = count < 0 ? 0 : count;
  void setAttendeeCount(final int count) => _attendeeCount = count < 0 ? 0 : count;

  void setLeadSpeaker({String? uid, String? imgSrc, String? name}) {
    _leadSpeakerUID = uid;
    _leadSpeakerImgSrc = imgSrc;
    _leadSpeakerName = name;
  }

  void clearLeadSpeaker() {
    _leadSpeakerUID = null;
    _leadSpeakerImgSrc = null;
    _leadSpeakerName = null;
  }

  bool containsMediaItem(final String src) => _media.map<String>((e) => e['src']!).toList().contains(src);

  Map<String, dynamic> _mediaItem({
    required String type,
    required String src,
    String title = '',
    String thumbnail = '',
  }) {
    return <String, dynamic>{
      'type': type,
      'src': src,
      'title': title,
      'thumbnailSrc': thumbnail.isEmpty ? null : thumbnail,
    };
  }

  void addMediaItem({required String type, required String src, String title = '', String thumbnail = ''}) {
    _media.add(_mediaItem(type: type, src: src, title: title, thumbnail: thumbnail));
  }

  /// Inserts at the front so [getKeyGraphic] / card thumbnail pick this image first.
  void prependMediaItem({required String type, required String src, String title = '', String thumbnail = ''}) {
    _media.insert(0, _mediaItem(type: type, src: src, title: title, thumbnail: thumbnail));
  }

  /// Replaces all key media with a single cover item (used by Change cover).
  void replaceKeyGraphic({
    required String type,
    required String src,
    String title = '',
    String thumbnail = '',
  }) {
    _media
      ..clear()
      ..add(_mediaItem(type: type, src: src, title: title, thumbnail: thumbnail));
  }

  void removeMediaItem(final Map<String, dynamic> thisEntry) => _media.remove(thisEntry);
  void resetMediaWithOriginal(List<Map<String, dynamic>> original) {
    _media.clear();
    _media.addAll(original.map((e) => Map<String, dynamic>.from(e)));
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
