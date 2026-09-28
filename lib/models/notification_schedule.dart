import 'package:cloud_firestore/cloud_firestore.dart';

/// How a [NotificationSchedule] picks the moment to send, relative to the
/// post's event date in Europe/London.
enum NotificationScheduleTiming {
  dayBefore('day_before'),
  morningOf('morning_of'),
  hoursBefore('hours_before');

  const NotificationScheduleTiming(this.wire);

  final String wire;

  static NotificationScheduleTiming? fromWire(String? raw) {
    final value = raw?.trim() ?? '';
    for (final timing in NotificationScheduleTiming.values) {
      if (timing.wire == value) return timing;
    }
    return null;
  }
}

/// Area-admin reminder stored in `notification_schedules/{id}`.
///
/// One row is one post tag at one location. The scheduled function reads these
/// documents. The hub page loads them; they are not part of the session store.
class NotificationSchedule {
  NotificationSchedule({
    required String id,
    bool enabled = true,
    required String postTagId,
    required String location,
    required NotificationScheduleTiming timing,
    String clockTime = '18:00',
    int hoursBefore = 2,
    String? lastSentPostId,
    DateTime? lastSentEventAt,
    DateTime? lastSentAt,
    String? lastError,
  }) {
    _id = id;
    _enabled = enabled;
    _postTagId = postTagId.trim();
    _location = location.trim();
    _timing = timing;
    _clockTime = _normalizeClock(clockTime);
    _hoursBefore = clampHoursBefore(hoursBefore);
    _lastSentPostId = _blankToNull(lastSentPostId);
    _lastSentEventAt = lastSentEventAt;
    _lastSentAt = lastSentAt;
    _lastError = _blankToNull(lastError);
  }

  NotificationSchedule.fromMap(
      final String id, final Map<String, dynamic> data) {
    _id = id;
    _enabled = data['Enabled'] == true;
    _postTagId = (data['PostTagId'] as String? ?? '').trim();
    _location = (data['Location'] as String? ?? '').trim();
    _timing =
        NotificationScheduleTiming.fromWire(data['TimingKind'] as String?);
    _clockTime = _normalizeClock(data['ClockTime'] as String? ?? '');
    _hoursBefore = clampHoursBefore(data['HoursBefore']);
    _lastSentPostId = _blankToNull(data['LastSentPostId'] as String?);
    _lastSentEventAt = _parseDateTime(data['LastSentEventAt']);
    _lastSentAt = _parseDateTime(data['LastSentAt']);
    _lastError = _blankToNull(data['LastError']?.toString());
  }

  late final String _id;
  late bool _enabled;
  late String _postTagId;
  late String _location;
  NotificationScheduleTiming? _timing;
  late String _clockTime;
  late int _hoursBefore;
  String? _lastSentPostId;
  DateTime? _lastSentEventAt;
  DateTime? _lastSentAt;
  String? _lastError;

  static const int minHoursBefore = 1;
  static const int maxHoursBefore = 48;

  static int clampHoursBefore(final Object? raw) {
    final parsed = raw is num ? raw.toInt() : int.tryParse('$raw') ?? 2;
    if (parsed < minHoursBefore) return minHoursBefore;
    if (parsed > maxHoursBefore) return maxHoursBefore;
    return parsed;
  }

  static String _normalizeClock(final String raw) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(raw.trim());
    if (match == null) return '18:00';
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return '18:00';
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  static String? _blankToNull(final String? raw) {
    final trimmed = raw?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    return trimmed;
  }

  static DateTime? _parseDateTime(final dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    return null;
  }

  /// Fields the hub may write. Last-sent fields stay with the function.
  Map<String, Object?> toConfigJson() {
    return {
      'Enabled': _enabled,
      'PostTagId': _postTagId,
      'Location': _location,
      'TimingKind': _timing?.wire ?? '',
      'ClockTime': _clockTime,
      'HoursBefore': _hoursBefore,
    };
  }

  Map<String, Object?> toJson() {
    return {
      ...toConfigJson(),
      if (_lastSentPostId != null) 'LastSentPostId': _lastSentPostId,
      if (_lastSentEventAt != null)
        'LastSentEventAt': Timestamp.fromDate(_lastSentEventAt!),
      if (_lastSentAt != null) 'LastSentAt': Timestamp.fromDate(_lastSentAt!),
      if (_lastError != null) 'LastError': _lastError,
    };
  }

  String get id => _id;
  bool get enabled => _enabled;
  String get postTagId => _postTagId;
  String get location => _location;
  NotificationScheduleTiming? get timing => _timing;
  String get clockTime => _clockTime;
  int get hoursBefore => _hoursBefore;
  String? get lastSentPostId => _lastSentPostId;
  DateTime? get lastSentEventAt => _lastSentEventAt;
  DateTime? get lastSentAt => _lastSentAt;
  String? get lastError => _lastError;

  void setEnabled(final bool enabled) => _enabled = enabled;
  void setPostTagId(final String postTagId) => _postTagId = postTagId.trim();
  void setLocation(final String location) => _location = location.trim();
  void setTiming(final NotificationScheduleTiming timing) => _timing = timing;
  void setClockTime(final String clockTime) =>
      _clockTime = _normalizeClock(clockTime);
  void setHoursBefore(final int hoursBefore) =>
      _hoursBefore = clampHoursBefore(hoursBefore);
}
