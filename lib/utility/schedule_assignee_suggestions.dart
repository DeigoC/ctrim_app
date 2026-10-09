import '../models/event/event_program.dart';

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

/// One-tap reuse of people who share a ministry on the same post.
///
/// A suggestion is another line with overlapping `tagIDs` and at least one
/// person. Standing roles always qualify. A timed line qualifies only when
/// the target is not standing and that line starts earlier. The lists are
/// not linked: applying copies people in, and later edits stay put.
class ScheduleAssigneeSuggestions {
  ScheduleAssigneeSuggestions._();

  static List<ScheduleAssigneeSuggestion> forRole({
    required Map<String, dynamic> role,
    required List<Map<String, dynamic>> roles,
  }) {
    final targetTags = EventProgram.tagIDsOf(role).toSet();
    if (targetTags.isEmpty) return const [];

    final targetId = role['id'];
    final targetUids = _uidsOf(role).toSet();
    final targetStanding = EventProgram.isStanding(role);
    final targetStart = role['start'] as DateTime?;

    final standing = <_Candidate>[];
    final earlier = <_Candidate>[];

    for (final other in roles) {
      if (other['id'] == targetId) continue;
      final otherTags = EventProgram.tagIDsOf(other);
      if (!otherTags.any(targetTags.contains)) continue;

      final uids = _uidsOf(other);
      if (uids.isEmpty) continue;
      if (uids.every(targetUids.contains)) continue;

      final candidate = _Candidate(
        roleId: other['id'] as int,
        title: (other['title'] as String?) ?? '',
        uids: uids,
        start: other['start'] as DateTime?,
      );

      if (EventProgram.isStanding(other)) {
        standing.add(candidate);
        continue;
      }
      if (targetStanding) continue;
      final otherStart = candidate.start;
      if (targetStart == null ||
          otherStart == null ||
          !otherStart.isBefore(targetStart)) {
        continue;
      }
      earlier.add(candidate);
    }

    standing.sort((a, b) {
      final byStart = _compareStart(a.start, b.start);
      if (byStart != 0) return byStart;
      return a.title.compareTo(b.title);
    });
    earlier.sort((a, b) {
      final byStart = _compareStart(a.start, b.start);
      if (byStart != 0) return byStart;
      return a.title.compareTo(b.title);
    });

    return [
      for (final candidate in standing) candidate.toSuggestion(),
      for (final candidate in earlier) candidate.toSuggestion(),
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
