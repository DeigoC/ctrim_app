/// Lane packing for the post schedule timeline.
///
/// Roles that overlap in time are placed in side-by-side lanes, the way a
/// calendar day view shows concurrent entries. Roles without both a start and
/// an end cannot be positioned and are returned separately.
library;

/// One role positioned on the timeline canvas.
class ScheduleTimelinePlacement {
  const ScheduleTimelinePlacement({
    required this.role,
    required this.start,
    required this.end,
    required this.laneIndex,
    required this.laneCount,
    required this.clusterIndex,
    required this.minutesFromStart,
  });

  final Map<String, dynamic> role;
  final DateTime start;
  final DateTime end;

  /// Lane this role occupies, left to right.
  final int laneIndex;

  /// Lanes shared by every role in this overlap cluster, so blocks that run at
  /// the same time get the same width.
  final int laneCount;

  /// Groups transitively overlapping roles; used to attach overflow markers.
  final int clusterIndex;

  /// Minutes between the timeline's first tick and this role's start.
  final double minutesFromStart;

  int get roleId => role['id'] as int;

  double get durationMinutes =>
      end.difference(start).inSeconds / Duration.secondsPerMinute;
}

/// Roles in a cluster that did not fit within the lane cap.
class ScheduleTimelineOverflow {
  const ScheduleTimelineOverflow({
    required this.clusterIndex,
    required this.roles,
    required this.start,
    required this.end,
    required this.minutesFromStart,
  });

  final int clusterIndex;
  final List<Map<String, dynamic>> roles;

  /// Earliest start / latest end among the hidden roles.
  final DateTime start;
  final DateTime end;
  final double minutesFromStart;

  int get count => roles.length;
}

/// Positions schedule roles into time-ordered lanes.
class ScheduleTimelineLayout {
  const ScheduleTimelineLayout({
    required this.placements,
    required this.overflows,
    required this.untimedRoles,
    required this.dayStart,
    required this.dayEnd,
  });

  /// Lanes rendered before roles spill into an overflow marker.
  static const int phoneLaneCap = 2;
  static const int wideLaneCap = 4;

  final List<ScheduleTimelinePlacement> placements;
  final List<ScheduleTimelineOverflow> overflows;

  /// Roles missing a start or end; they cannot be drawn on the time axis.
  final List<Map<String, dynamic>> untimedRoles;

  /// Timeline bounds, rounded out to whole hours. Null when nothing is timed.
  final DateTime? dayStart;
  final DateTime? dayEnd;

  bool get isEmpty => placements.isEmpty;

  bool get hasOverlaps => placements.any((final p) => p.laneCount > 1);

  double get totalMinutes {
    final start = dayStart;
    final end = dayEnd;
    if (start == null || end == null) return 0;
    return end.difference(start).inSeconds / Duration.secondsPerMinute;
  }

  ScheduleTimelineOverflow? overflowForCluster(final int clusterIndex) {
    for (final overflow in overflows) {
      if (overflow.clusterIndex == clusterIndex) return overflow;
    }
    return null;
  }

  /// Packs [roles] into lanes, hiding anything past [laneCap] behind an
  /// overflow marker. [finishTime] extends the axis to the event's end.
  static ScheduleTimelineLayout build({
    required List<Map<String, dynamic>> roles,
    int laneCap = phoneLaneCap,
    DateTime? finishTime,
  }) {
    final cap = laneCap < 1 ? 1 : laneCap;
    final untimed = <Map<String, dynamic>>[];
    final timed =
        <({Map<String, dynamic> role, DateTime start, DateTime end})>[];

    for (final role in roles) {
      final start = role['start'] as DateTime?;
      final end = role['end'] as DateTime?;
      if (start == null || end == null) {
        untimed.add(role);
        continue;
      }
      timed.add(
          (role: role, start: start, end: end.isBefore(start) ? start : end));
    }

    if (timed.isEmpty) {
      return ScheduleTimelineLayout(
        placements: const [],
        overflows: const [],
        untimedRoles: untimed,
        dayStart: null,
        dayEnd: null,
      );
    }

    timed.sort((final a, final b) {
      final byStart = a.start.compareTo(b.start);
      if (byStart != 0) return byStart;
      return b.end.difference(b.start).compareTo(a.end.difference(a.start));
    });

    var latestEnd = timed.first.end;
    for (final entry in timed) {
      if (entry.end.isAfter(latestEnd)) latestEnd = entry.end;
    }
    if (finishTime != null && finishTime.isAfter(latestEnd)) {
      latestEnd = finishTime;
    }

    final dayStart = _floorToHour(timed.first.start);
    final dayEnd = _ceilToHour(latestEnd);

    final placements = <ScheduleTimelinePlacement>[];
    final overflows = <ScheduleTimelineOverflow>[];

    var clusterIndex = 0;
    var index = 0;
    while (index < timed.length) {
      final clusterEndIndex = _clusterEndIndex(timed, index);
      _placeCluster(
        timed: timed,
        firstIndex: index,
        lastIndex: clusterEndIndex,
        clusterIndex: clusterIndex,
        cap: cap,
        dayStart: dayStart,
        placements: placements,
        overflows: overflows,
      );
      index = clusterEndIndex + 1;
      clusterIndex++;
    }

    return ScheduleTimelineLayout(
      placements: placements,
      overflows: overflows,
      untimedRoles: untimed,
      dayStart: dayStart,
      dayEnd: dayEnd,
    );
  }

  /// Last index of the run of roles that transitively overlap [firstIndex].
  static int _clusterEndIndex(
    final List<({Map<String, dynamic> role, DateTime start, DateTime end})>
        timed,
    final int firstIndex,
  ) {
    var lastIndex = firstIndex;
    var clusterEnd = timed[firstIndex].end;
    for (var i = firstIndex + 1; i < timed.length; i++) {
      if (!timed[i].start.isBefore(clusterEnd)) break;
      if (timed[i].end.isAfter(clusterEnd)) clusterEnd = timed[i].end;
      lastIndex = i;
    }
    return lastIndex;
  }

  static void _placeCluster({
    required List<({Map<String, dynamic> role, DateTime start, DateTime end})>
        timed,
    required int firstIndex,
    required int lastIndex,
    required int clusterIndex,
    required int cap,
    required DateTime dayStart,
    required List<ScheduleTimelinePlacement> placements,
    required List<ScheduleTimelineOverflow> overflows,
  }) {
    final laneEnds = <DateTime>[];
    final lanes = <int>[];

    for (var i = firstIndex; i <= lastIndex; i++) {
      final entry = timed[i];
      var lane = -1;
      for (var candidate = 0; candidate < laneEnds.length; candidate++) {
        if (!entry.start.isBefore(laneEnds[candidate])) {
          lane = candidate;
          break;
        }
      }
      if (lane == -1) {
        lane = laneEnds.length;
        laneEnds.add(entry.end);
      } else {
        laneEnds[lane] = entry.end;
      }
      lanes.add(lane);
    }

    final laneCount = laneEnds.length < cap ? laneEnds.length : cap;
    final hidden = <Map<String, dynamic>>[];
    DateTime? hiddenStart;
    DateTime? hiddenEnd;

    for (var i = firstIndex; i <= lastIndex; i++) {
      final entry = timed[i];
      final lane = lanes[i - firstIndex];
      if (lane >= cap) {
        hidden.add(entry.role);
        if (hiddenStart == null || entry.start.isBefore(hiddenStart)) {
          hiddenStart = entry.start;
        }
        if (hiddenEnd == null || entry.end.isAfter(hiddenEnd)) {
          hiddenEnd = entry.end;
        }
        continue;
      }
      placements.add(ScheduleTimelinePlacement(
        role: entry.role,
        start: entry.start,
        end: entry.end,
        laneIndex: lane,
        laneCount: laneCount,
        clusterIndex: clusterIndex,
        minutesFromStart: _minutesBetween(dayStart, entry.start),
      ));
    }

    if (hidden.isNotEmpty && hiddenStart != null && hiddenEnd != null) {
      overflows.add(ScheduleTimelineOverflow(
        clusterIndex: clusterIndex,
        roles: hidden,
        start: hiddenStart,
        end: hiddenEnd,
        minutesFromStart: _minutesBetween(dayStart, hiddenStart),
      ));
    }
  }

  static double _minutesBetween(final DateTime from, final DateTime to) =>
      to.difference(from).inSeconds / Duration.secondsPerMinute;

  static DateTime _floorToHour(final DateTime time) =>
      DateTime(time.year, time.month, time.day, time.hour);

  static DateTime _ceilToHour(final DateTime time) {
    final floored = _floorToHour(time);
    if (floored.isAtSameMomentAs(time)) return floored;
    return floored.add(const Duration(hours: 1));
  }
}
