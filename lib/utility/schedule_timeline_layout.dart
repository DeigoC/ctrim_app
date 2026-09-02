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

/// A role that runs for most of the event rather than occupying a slot in the
/// running order — sound, media, stewarding and the like.
///
/// These are lifted off the canvas so a single long role cannot push the whole
/// running order into overflow lanes.
class ScheduleCoverageRole {
  const ScheduleCoverageRole({
    required this.role,
    required this.start,
    required this.end,
  });

  final Map<String, dynamic> role;
  final DateTime start;
  final DateTime end;

  int get roleId => role['id'] as int;
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
    required this.coverageRoles,
    required this.untimedRoles,
    required this.dayStart,
    required this.dayEnd,
  });

  /// Lanes rendered before roles spill into an overflow marker.
  static const int phoneLaneCap = 2;
  static const int wideLaneCap = 4;

  /// Share of the scheduled span a role must fill to count as covering the
  /// event instead of taking a turn in the running order.
  static const double coverageSpanRatio = 0.5;

  /// A covering role has to actually run alongside other items; a long role in
  /// a back-to-back running order is still part of the sequence.
  static const int minCoverageOverlaps = 2;

  /// Guards short posts, where a handful of minutes can still be half the span.
  static const Duration minCoverageDuration = Duration(minutes: 30);

  final List<ScheduleTimelinePlacement> placements;
  final List<ScheduleTimelineOverflow> overflows;

  /// Long-running roles shown in a band above the canvas, earliest first.
  final List<ScheduleCoverageRole> coverageRoles;

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
  ///
  /// Roles covering most of the schedule are pulled out into [coverageRoles]
  /// first, so the canvas shows the running order rather than a wall of
  /// all-morning duty blocks.
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
        coverageRoles: const [],
        untimedRoles: untimed,
        dayStart: null,
        dayEnd: null,
      );
    }

    final coverage = _extractCoverageRoles(timed);

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

    final dayStart = _floorToTick(timed.first.start);
    final dayEnd = _ceilToTick(latestEnd);

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
      coverageRoles: coverage,
      untimedRoles: untimed,
      dayStart: dayStart,
      dayEnd: dayEnd,
    );
  }

  /// Removes roles that span most of the schedule from [timed] and returns
  /// them, earliest first.
  ///
  /// Nothing is removed when every role qualifies, since an empty canvas is
  /// worse than a crowded one.
  static List<ScheduleCoverageRole> _extractCoverageRoles(
    final List<({Map<String, dynamic> role, DateTime start, DateTime end})>
        timed,
  ) {
    if (timed.length < 3) return const [];

    var spanStart = timed.first.start;
    var spanEnd = timed.first.end;
    for (final entry in timed) {
      if (entry.start.isBefore(spanStart)) spanStart = entry.start;
      if (entry.end.isAfter(spanEnd)) spanEnd = entry.end;
    }

    final spanSeconds = spanEnd.difference(spanStart).inSeconds;
    if (spanSeconds <= 0) return const [];

    final candidates = <int>{};
    for (var i = 0; i < timed.length; i++) {
      final entry = timed[i];
      final durationSeconds = entry.end.difference(entry.start).inSeconds;
      if (durationSeconds < minCoverageDuration.inSeconds) continue;
      if (durationSeconds / spanSeconds < coverageSpanRatio) continue;
      if (_overlapCount(timed, i) < minCoverageOverlaps) continue;
      candidates.add(i);
    }

    if (candidates.isEmpty || candidates.length == timed.length) {
      return const [];
    }

    final coverage = <ScheduleCoverageRole>[];
    for (final index in candidates.toList()..sort()) {
      final entry = timed[index];
      coverage.add(ScheduleCoverageRole(
        role: entry.role,
        start: entry.start,
        end: entry.end,
      ));
    }
    for (final index in candidates.toList()..sort((a, b) => b.compareTo(a))) {
      timed.removeAt(index);
    }

    coverage.sort((final a, final b) {
      final byStart = a.start.compareTo(b.start);
      if (byStart != 0) return byStart;
      return b.end.compareTo(a.end);
    });
    return coverage;
  }

  /// How many other roles run at the same time as the one at [index].
  static int _overlapCount(
    final List<({Map<String, dynamic> role, DateTime start, DateTime end})>
        timed,
    final int index,
  ) {
    final entry = timed[index];
    var count = 0;
    for (var i = 0; i < timed.length; i++) {
      if (i == index) continue;
      final other = timed[i];
      if (entry.start.isBefore(other.end) && other.start.isBefore(entry.end)) {
        count++;
      }
    }
    return count;
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

  /// Bounds land on the half hour, matching the ticks the canvas draws, so a
  /// schedule starting at five to ten does not open on a blank hour.
  static const int _boundaryMinutes = 30;

  static DateTime _floorToTick(final DateTime time) {
    final minute = time.minute - time.minute % _boundaryMinutes;
    return DateTime(time.year, time.month, time.day, time.hour, minute);
  }

  static DateTime _ceilToTick(final DateTime time) {
    final floored = _floorToTick(time);
    if (floored.isAtSameMomentAs(time)) return floored;
    return floored.add(const Duration(minutes: _boundaryMinutes));
  }
}
