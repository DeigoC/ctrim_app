/// Staffing layout for Ministry Schedule's whole-event page.
///
/// Coverage roles (standing, or long enough to count as all-event) sit in
/// [duties]. Everything else with a start and finish is a turn on the clock
/// rail. Card height is not the duration — [ScheduleAgendaTurn.durationFraction]
/// is a bar, so faces stay a fixed size.
library;

import 'schedule_timeline_layout.dart';
import 'team_rota.dart';

/// One all-event or long-coverage role.
class ScheduleAgendaDuty {
  const ScheduleAgendaDuty({
    required this.role,
    required this.start,
    required this.end,
  });

  final Map<String, dynamic> role;
  final DateTime? start;
  final DateTime? end;

  int get roleId => ScheduleAgendaLayout.roleIdOf(role);

  String get title => ScheduleAgendaLayout.titleOf(role);
}

/// One running-order slot.
class ScheduleAgendaTurn {
  const ScheduleAgendaTurn({
    required this.role,
    required this.start,
    required this.end,
    required this.durationMinutes,
    required this.durationFraction,
    required this.sameAsDutyTitle,
  });

  final Map<String, dynamic> role;
  final DateTime start;
  final DateTime end;

  /// Clock length. Zero when the finish was clamped back to the start.
  final double durationMinutes;

  /// Share of the longest turn, never below [ScheduleAgendaLayout.minDurationFraction]
  /// when the turn has any length. Zero when the turn has no length.
  final double durationFraction;

  /// Set when this turn's people are exactly the people on an on-duty role.
  /// Empty assignee lists never match.
  final String? sameAsDutyTitle;

  int get roleId => ScheduleAgendaLayout.roleIdOf(role);

  String get title => ScheduleAgendaLayout.titleOf(role);
}

/// Turns that overlap, so they share one clock label.
class ScheduleAgendaCluster {
  const ScheduleAgendaCluster({
    required this.start,
    required this.turns,
  });

  /// Earliest start in [turns]. The gutter prints this once.
  final DateTime start;
  final List<ScheduleAgendaTurn> turns;
}

/// Duties, then the running order, then roles with no usable clock time.
class ScheduleAgendaLayout {
  const ScheduleAgendaLayout({
    required this.duties,
    required this.clusters,
    required this.untimedRoles,
    required this.dayStart,
    required this.dayEnd,
  });

  /// Shortest bar a turn with any length can draw, so a five-minute song
  /// stays visible next to a two-hour meeting.
  static const double minDurationFraction = 0.12;

  /// High enough that a Sunday service is not pushed into timeline overflow.
  static const int _laneCap = 64;

  final List<ScheduleAgendaDuty> duties;
  final List<ScheduleAgendaCluster> clusters;
  final List<Map<String, dynamic>> untimedRoles;

  /// Axis for the running-order silhouette. Null when there is no timed turn.
  final DateTime? dayStart;
  final DateTime? dayEnd;

  bool get hasDuties => duties.isNotEmpty;
  bool get hasRunningOrder => clusters.isNotEmpty;

  static int roleIdOf(final Map<String, dynamic> role) =>
      (role['id'] as num).toInt();

  static String titleOf(final Map<String, dynamic> role) =>
      (role['title'] as String?)?.trim() ?? '';

  static ScheduleAgendaLayout build(final List<Map<String, dynamic>> roles) {
    final timeline = ScheduleTimelineLayout.build(
      roles: roles,
      laneCap: _laneCap,
    );
    final duties = [
      for (final coverage in timeline.coverageRoles)
        ScheduleAgendaDuty(
          role: coverage.role,
          start: coverage.start,
          end: coverage.end,
        ),
    ];

    final drafts = <int,
        List<({Map<String, dynamic> role, DateTime start, DateTime end})>>{};
    void addDraft(
      final int clusterIndex,
      final Map<String, dynamic> role,
      final DateTime start,
      final DateTime end,
    ) {
      drafts.putIfAbsent(clusterIndex, () => []).add((
        role: role,
        start: start,
        end: end.isBefore(start) ? start : end,
      ));
    }

    for (final placement in timeline.placements) {
      addDraft(
        placement.clusterIndex,
        placement.role,
        placement.start,
        placement.end,
      );
    }
    for (final overflow in timeline.overflows) {
      for (final role in overflow.roles) {
        final start = role['start'] as DateTime?;
        final end = role['end'] as DateTime?;
        if (start == null || end == null) continue;
        addDraft(overflow.clusterIndex, role, start, end);
      }
    }

    var longest = 0.0;
    for (final cluster in drafts.values) {
      for (final draft in cluster) {
        final minutes = _minutes(draft.start, draft.end);
        if (minutes > longest) longest = minutes;
      }
    }

    final clusters = <ScheduleAgendaCluster>[];
    final indexes = drafts.keys.toList()..sort();
    for (final index in indexes) {
      final cluster = drafts[index]!
        ..sort((final a, final b) {
          final byStart = a.start.compareTo(b.start);
          if (byStart != 0) return byStart;
          return roleIdOf(a.role).compareTo(roleIdOf(b.role));
        });
      clusters.add(ScheduleAgendaCluster(
        start: cluster.first.start,
        turns: [
          for (final draft in cluster)
            ScheduleAgendaTurn(
              role: draft.role,
              start: draft.start,
              end: draft.end,
              durationMinutes: _minutes(draft.start, draft.end),
              durationFraction: _fraction(
                _minutes(draft.start, draft.end),
                longest,
              ),
              sameAsDutyTitle: _sameAsDutyTitle(draft.role, duties),
            ),
        ],
      ));
    }

    return ScheduleAgendaLayout(
      duties: duties,
      clusters: clusters,
      untimedRoles: List<Map<String, dynamic>>.from(timeline.untimedRoles),
      dayStart: timeline.dayStart,
      dayEnd: timeline.dayEnd,
    );
  }

  /// Role titles [uid] is on, earliest start first. A whole-event duty with
  /// no clock time comes before timed slots.
  List<String> titlesAssignedTo(final String uid) {
    if (uid.isEmpty) return const [];
    final entries = <({DateTime? start, int id, String title})>[];
    void consider(final Map<String, dynamic> role, final DateTime? start) {
      if (!TeamRotaQuery.isAssignedTo(role, uid)) return;
      final title = titleOf(role);
      if (title.isEmpty) return;
      entries.add((start: start, id: roleIdOf(role), title: title));
    }

    for (final duty in duties) {
      consider(duty.role, duty.start);
    }
    for (final cluster in clusters) {
      for (final turn in cluster.turns) {
        consider(turn.role, turn.start);
      }
    }
    for (final role in untimedRoles) {
      consider(role, role['start'] as DateTime?);
    }

    entries.sort((final a, final b) {
      final aStart = a.start;
      final bStart = b.start;
      if (aStart == null && bStart == null) return a.id.compareTo(b.id);
      if (aStart == null) return -1;
      if (bStart == null) return 1;
      final byStart = aStart.compareTo(bStart);
      if (byStart != 0) return byStart;
      return a.id.compareTo(b.id);
    });
    return [for (final entry in entries) entry.title];
  }

  /// Duty title when [role] has the same non-empty people as an on-duty role.
  String? sameAsDutyTitleFor(final Map<String, dynamic> role) =>
      _sameAsDutyTitle(role, duties);

  /// First empty role in visual order (duties, then turns, then untimed)
  /// that [include] accepts.
  int? firstGapRoleId(final bool Function(Map<String, dynamic> role) include) {
    bool gap(final Map<String, dynamic> role) =>
        TeamRotaQuery.uidsOf(role).isEmpty && include(role);

    for (final duty in duties) {
      if (gap(duty.role)) return duty.roleId;
    }
    for (final cluster in clusters) {
      for (final turn in cluster.turns) {
        if (gap(turn.role)) return turn.roleId;
      }
    }
    for (final role in untimedRoles) {
      if (gap(role)) return roleIdOf(role);
    }
    return null;
  }

  static double _minutes(final DateTime start, final DateTime end) =>
      end.difference(start).inSeconds / Duration.secondsPerMinute;

  static double _fraction(final double minutes, final double longest) {
    if (minutes <= 0 || longest <= 0) return 0;
    final raw = minutes / longest;
    if (raw >= 1) return 1;
    if (raw < minDurationFraction) return minDurationFraction;
    return raw;
  }

  static String? _sameAsDutyTitle(
    final Map<String, dynamic> role,
    final List<ScheduleAgendaDuty> duties,
  ) {
    final uids = TeamRotaQuery.uidsOf(role);
    if (uids.isEmpty) return null;
    for (final duty in duties) {
      if (!TeamRotaQuery.sameAssigneeIds(
          uids, TeamRotaQuery.uidsOf(duty.role))) {
        continue;
      }
      final title = duty.title;
      if (title.isEmpty) return null;
      return title;
    }
    return null;
  }
}
