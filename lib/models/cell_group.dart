import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Status values for [CellGroup.status].
class CellGroupStatus {
  static const String active = 'active';
  static const String paused = 'paused';
  static const String archived = 'archived';

  static const List<String> all = [active, paused, archived];
}

/// Durable cell group head stored in `cell_groups/{id}`.
///
/// Guest-safe public fields only on this doc. Roster lives in
/// `cell_groups/{id}/supplemental/roster`. Venue/address omitted in V1.
///
/// Catalogue tiles use the first leader's portrait. [keyGraphicSrc] is a wider
/// cover for the detail page only (optional). [media] is the photo gallery.
class CellGroup {
  late String _id, _name, _summary, _location, _status, _meetingTime, _createdByUserID;
  late List<String> _leaderUserIds, _leaderAuthIds;
  late List<Map<String, dynamic>> _media;
  late int _memberCount;
  int? _meetingWeekday;
  String? _keyGraphicSrc;
  DateTime? _createdAt, _updatedAt;

  static const int maxMediaItems = 8;

  CellGroup({
    required String id,
    required String name,
    String summary = '',
    String location = 'Belfast',
    List<String> leaderUserIds = const [],
    List<String> leaderAuthIds = const [],
    List<Map<String, dynamic>> media = const [],
    String? keyGraphicSrc,
    int memberCount = 0,
    String status = CellGroupStatus.active,
    int? meetingWeekday,
    String meetingTime = '',
    String createdByUserID = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    _id = id;
    _name = name;
    _summary = summary;
    _location = location;
    _leaderUserIds = List<String>.from(leaderUserIds);
    _leaderAuthIds = List<String>.from(leaderAuthIds);
    _media = media.map((e) => Map<String, dynamic>.from(e)).toList();
    _keyGraphicSrc = keyGraphicSrc;
    _memberCount = memberCount < 0 ? 0 : memberCount;
    _status = status;
    _meetingWeekday = meetingWeekday;
    _meetingTime = meetingTime;
    _createdByUserID = createdByUserID;
    _createdAt = createdAt;
    _updatedAt = updatedAt;
    _syncKeyGraphicWithMedia();
  }

  CellGroup.fromMap(final String id, final Map<String, dynamic> data)
      : _id = id,
        _name = (data['Name'] as String?) ?? '',
        _summary = (data['Summary'] as String?) ?? '',
        _location = (data['Location'] as String?) ?? 'Belfast',
        _leaderUserIds = _parseStringList(data['LeaderUserIds']),
        _leaderAuthIds = _parseStringList(data['LeaderAuthIds']),
        _media = _parseMedia(data['Media']),
        _keyGraphicSrc = data['KeyGraphicSrc'] as String?,
        _memberCount = (data['MemberCount'] as num?)?.toInt() ?? 0,
        _status = (data['Status'] as String?) ?? CellGroupStatus.active,
        _meetingWeekday = (data['MeetingWeekday'] as num?)?.toInt(),
        _meetingTime = (data['MeetingTime'] as String?) ?? '',
        _createdByUserID = (data['CreatedByUserID'] as String?) ?? '',
        _createdAt = _parseTimestamp(data['CreatedAt']),
        _updatedAt = _parseTimestamp(data['UpdatedAt']) {
    _syncKeyGraphicWithMedia();
  }

  static List<String> _parseStringList(final dynamic raw) {
    if (raw is! List) return <String>[];
    return raw.map((e) => e.toString()).where((id) => id.isNotEmpty).toList();
  }

  static DateTime? _parseTimestamp(final dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return null;
  }

  static List<Map<String, dynamic>> _parseMedia(final dynamic raw) {
    if (raw is! List) return <Map<String, dynamic>>[];
    final results = <Map<String, dynamic>>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      final map = Map<String, dynamic>.from(entry);
      final src = (map['src'] as String?) ?? '';
      if (src.isEmpty) continue;
      results.add({
        'title': map['title'] ?? '',
        'src': src,
        'type': map['type'] ?? 'img',
        'thumbnailSrc': map['thumbnailSrc'],
      });
    }
    return results;
  }

  Map<String, dynamic> toJson() {
    return {
      'Name': _name,
      'Summary': _summary,
      'Location': _location,
      'LeaderUserIds': _leaderUserIds,
      'LeaderAuthIds': _leaderAuthIds,
      'Media': _media.map((e) => Map<String, dynamic>.from(e)).toList(),
      'KeyGraphicSrc': _keyGraphicSrc,
      'MemberCount': _memberCount,
      'Status': _status,
      'MeetingWeekday': _meetingWeekday,
      'MeetingTime': _meetingTime,
      'CreatedByUserID': _createdByUserID,
      if (_createdAt != null) 'CreatedAt': Timestamp.fromDate(_createdAt!),
      if (_updatedAt != null) 'UpdatedAt': Timestamp.fromDate(_updatedAt!),
    };
  }

  String get id => _id;
  String get name => _name;
  String get summary => _summary;
  String get location => _location;
  List<String> get leaderUserIds => UnmodifiableListView(_leaderUserIds);
  List<String> get leaderAuthIds => UnmodifiableListView(_leaderAuthIds);
  List<Map<String, dynamic>> get media => UnmodifiableListView(_media);
  String? get keyGraphicSrc => _keyGraphicSrc;
  int get memberCount => _memberCount;
  String get status => _status;
  int? get meetingWeekday => _meetingWeekday;
  String get meetingTime => _meetingTime;
  String get createdByUserID => _createdByUserID;
  DateTime? get createdAt => _createdAt;
  DateTime? get updatedAt => _updatedAt;

  bool get isActive => _status == CellGroupStatus.active;
  bool get isPaused => _status == CellGroupStatus.paused;
  bool get isArchived => _status == CellGroupStatus.archived;
  bool get hasKeyGraphic =>
      _keyGraphicSrc != null && _keyGraphicSrc!.isNotEmpty;

  bool isLeaderUser(final String userId) =>
      userId.isNotEmpty && _leaderUserIds.contains(userId);

  bool isLeaderAuth(final String authId) =>
      authId.isNotEmpty && _leaderAuthIds.contains(authId);

  /// Guest-safe cadence line, e.g. "Tuesday · 19:30" or empty.
  String get cadenceLabel {
    final weekday = _weekdayName(_meetingWeekday);
    final time = _meetingTime.trim();
    if (weekday == null && time.isEmpty) return '';
    if (weekday == null) return time;
    if (time.isEmpty) return weekday;
    return '$weekday · $time';
  }

  static String? _weekdayName(final int? weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return null;
    }
  }

  void setName(final String name) => _name = name;
  void setSummary(final String summary) => _summary = summary;
  void setLocation(final String location) => _location = location;
  void setStatus(final String status) => _status = status;
  void setMeetingWeekday(final int? weekday) => _meetingWeekday = weekday;
  void setMeetingTime(final String time) => _meetingTime = time;
  void setMemberCount(final int count) => _memberCount = count < 0 ? 0 : count;
  void setUpdatedAt(final DateTime value) => _updatedAt = value;

  void setLeaders({
    required List<String> userIds,
    required List<String> authIds,
  }) {
    _leaderUserIds = List<String>.from(userIds);
    _leaderAuthIds = authIds.where((id) => id.isNotEmpty).toList();
  }

  void setMedia(final List<Map<String, dynamic>> media) {
    _media = media.map((e) => Map<String, dynamic>.from(e)).toList();
    _syncKeyGraphicWithMedia();
  }

  /// Returns false if at capacity or [src] already present.
  bool addMediaItem(final Map<String, dynamic> item) {
    final src = (item['src'] as String?) ?? '';
    if (src.isEmpty) return false;
    if (_media.length >= maxMediaItems) return false;
    if (_media.any((e) => e['src'] == src)) return false;
    _media.add({
      'title': item['title'] ?? '',
      'src': src,
      'type': item['type'] ?? 'img',
      'thumbnailSrc': item['thumbnailSrc'],
    });
    return true;
  }

  void removeMediaItem(final String src) {
    _media.removeWhere((e) => e['src'] == src);
    if (_keyGraphicSrc == src) _keyGraphicSrc = null;
  }

  /// Sets the detail-page cover. [src] must already be in [media], or null to clear.
  bool setKeyGraphicSrc(final String? src) {
    if (src == null || src.isEmpty) {
      _keyGraphicSrc = null;
      return true;
    }
    if (!_media.any((e) => e['src'] == src)) return false;
    _keyGraphicSrc = src;
    return true;
  }

  void _syncKeyGraphicWithMedia() {
    if (_keyGraphicSrc == null || _keyGraphicSrc!.isEmpty) {
      _keyGraphicSrc = null;
      return;
    }
    if (!_media.any((e) => e['src'] == _keyGraphicSrc)) {
      _keyGraphicSrc = null;
    }
  }
}
