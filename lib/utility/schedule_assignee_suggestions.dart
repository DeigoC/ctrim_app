import '../models/event/event_program.dart';
import 'schedule_timeline_layout.dart';

/// People already on another line of this post who share a ministry.
class ScheduleAssigneeSuggestion {
  const ScheduleAssigneeSuggestion({
    required this.sourceRoleId,
    required this.sourceTitle,
    required this.uids,
  });

  final int sourceRoleId;
  final String sourceTitle;

  /// People on the source line. Applying unions these into the target.
  final List<String> uids;
}

/// One-tap reuse of whole-event people on a matching line.
///
/// A suggestion is an All event role — declared standing, or a long line the
/// timeline already lifts into that band — that shares a ministry, or that
/// also has no ministry when this line has none. It needs at least one person.
/// An earlier timed slot is not a source. The lists are not linked: applying
/// copies people in, and later edits stay put.
class ScheduleAssigneeSuggestions {
  ScheduleAssigneeSuggestions._();

  static List<ScheduleAssigneeSuggestion> forRole({
    required Map<String, dynamic> role,
    required List<Map<String, dynamic>> roles,
  }) {
    final targetTags = EventProgram.tagIDsOf(role).toSet();
    final targetId = role['id'];
    final targetUids = _uidsOf(role).toSet();
    final sources = ScheduleTimelineLayout.build(roles: roles).coverageRoles;

    final candidates = <_Candidate>[];
    for (final coverage in sources) {
      final other = coverage.role;
      if (other['id'] == targetId) continue;
      if (!_matchesMinistries(targetTags, EventProgram.tagIDsOf(other))) {
        continue;
      }

      final uids = _uidsOf(other);
      if (uids.isEmpty) continue;
      if (uids.every(targetUids.contains)) continue;

      candidates.add(_Candidate(
        roleId: other['id'] as int,
        title: (other['title'] as String?) ?? '',
        uids: uids,
        start: other['start'] as DateTime?,
      ));
    }

    candidates.sort((a, b) {
      final byStart = _compareStart(a.start, b.start);
      if (byStart != 0) return byStart;
      return a.title.compareTo(b.title);
    });

    return [
      for (final candidate in candidates) candidate.toSuggestion(),
    ];
  }

  /// People already chosen, then anyone from [adding] who is not already there.
  static List<String> unionAssignees({
    required List<String> current,
    required List<String> adding,
  }) {
    final result = List<String>.from(current);
    for (final id in adding) {
      if (id.isEmpty || result.contains(id)) continue;
      result.add(id);
    }
    return result;
  }

  /// Shared ministry, or both lines have none.
  static bool _matchesMinistries(
    final Set<String> targetTags,
    final List<String> otherTags,
  ) {
    if (targetTags.isEmpty) return otherTags.isEmpty;
    return otherTags.any(targetTags.contains);
  }

  static List<String> _uidsOf(final Map<String, dynamic> role) {
    final raw = role['uids'];
    if (raw is! List) return const [];
    return raw.map((e) => e.toString()).where((id) => id.isNotEmpty).toList();
  }

  static int _compareStart(final DateTime? a, final DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return a.compareTo(b);
  }
}

class _Candidate {
  const _Candidate({
    required this.roleId,
    required this.title,
    required this.uids,
    required this.start,
  });

  final int roleId;
  final String title;
  final List<String> uids;
  final DateTime? start;

  ScheduleAssigneeSuggestion toSuggestion() {
    return ScheduleAssigneeSuggestion(
      sourceRoleId: roleId,
      sourceTitle: title,
      uids: uids,
    );
  }
}
