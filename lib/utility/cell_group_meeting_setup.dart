/// Why a stored period-parent id cannot be used for a new cell-group meeting.
enum CellGroupMeetingParentIssue {
  missing,
  notPeriodParent,
}

/// Pure checks for the cell-group Add meeting shortcut.
class CellGroupMeetingSetup {
  static CellGroupMeetingParentIssue? parentIssue({
    required bool exists,
    required bool isPeriodParent,
  }) {
    if (!exists) return CellGroupMeetingParentIssue.missing;
    if (!isPeriodParent) return CellGroupMeetingParentIssue.notPeriodParent;
    return null;
  }

  static bool templateIncludesGroup(
    final Iterable<String> cellGroupIDs,
    final String groupId,
  ) {
    return groupId.isNotEmpty && cellGroupIDs.contains(groupId);
  }

  /// Template links first, then [extraCellGroupIDs] that are not already present.
  static List<String> cellGroupIdsForNewMeeting({
    required Iterable<String> templateCellGroupIDs,
    Iterable<String> extraCellGroupIDs = const [],
  }) {
    final ids = <String>[];
    void add(final String id) {
      if (id.isEmpty || ids.contains(id)) return;
      ids.add(id);
    }

    for (final id in templateCellGroupIDs) {
      add(id);
    }
    for (final id in extraCellGroupIDs) {
      add(id);
    }
    return ids;
  }
}
