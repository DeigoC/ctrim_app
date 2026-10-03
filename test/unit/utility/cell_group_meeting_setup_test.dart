import 'package:flutter_test/flutter_test.dart';

import 'package:ctrim_app/utility/cell_group_meeting_setup.dart';

void main() {
  group('CellGroupMeetingSetup', () {
    test('parentIssue rejects a missing or non-period post', () {
      expect(
        CellGroupMeetingSetup.parentIssue(
          exists: false,
          isPeriodParent: false,
        ),
        CellGroupMeetingParentIssue.missing,
      );
      expect(
        CellGroupMeetingSetup.parentIssue(
          exists: true,
          isPeriodParent: false,
        ),
        CellGroupMeetingParentIssue.notPeriodParent,
      );
      expect(
        CellGroupMeetingSetup.parentIssue(
          exists: true,
          isPeriodParent: true,
        ),
        isNull,
      );
    });

    test('templateIncludesGroup requires this group id', () {
      expect(
        CellGroupMeetingSetup.templateIncludesGroup(['cg1', 'cg2'], 'cg1'),
        isTrue,
      );
      expect(
        CellGroupMeetingSetup.templateIncludesGroup(['cg2'], 'cg1'),
        isFalse,
      );
      expect(
        CellGroupMeetingSetup.templateIncludesGroup(['cg1'], ''),
        isFalse,
      );
    });

    test('cellGroupIdsForNewMeeting keeps template ids and adds the group', () {
      expect(
        CellGroupMeetingSetup.cellGroupIdsForNewMeeting(
          templateCellGroupIDs: ['cg-other', 'cg1'],
          extraCellGroupIDs: ['cg1', '', 'cg-extra'],
        ),
        ['cg-other', 'cg1', 'cg-extra'],
      );
    });
  });
}
