import 'package:flutter_test/flutter_test.dart';

import 'package:ctrim_app/models/cell_group.dart';
import 'package:ctrim_app/models/event/event_head.dart';
import 'package:ctrim_app/models/user.dart';
import 'package:ctrim_app/utility/personal_cell_group_meetings.dart';

void main() {
  group('PersonalCellGroupMeetings', () {
    CellGroup group({
      required String id,
      required String name,
      List<String> leaderUserIds = const [],
    }) {
      return CellGroup(
        id: id,
        name: name,
        leaderUserIds: leaderUserIds,
      );
    }

    EventHead meeting({
      required String id,
      required DateTime eventDate,
      required List<String> cellGroupIDs,
      String title = 'Meeting',
    }) {
      final head = EventHead(id: id, title: title);
      head.setEventDate(eventDate);
      head.setCellGroupIDs(cellGroupIDs);
      return head;
    }

    test('meetingsForMember filters to member groups and sorts soonest first', () {
      final alpha = group(id: 'cg-a', name: 'Alpha');
      final beta = group(id: 'cg-b', name: 'Beta');
      final memberGroups = [alpha, beta];
      final memberGroupIds = {'cg-a', 'cg-b'};

      final rows = PersonalCellGroupMeetings.meetingsForMember(
        meetings: [
          meeting(
            id: 'm2',
            eventDate: DateTime(2024, 7, 10),
            cellGroupIDs: ['cg-b'],
          ),
          meeting(
            id: 'm1',
            eventDate: DateTime(2024, 7, 5),
            cellGroupIDs: ['cg-a'],
          ),
          meeting(
            id: 'other',
            eventDate: DateTime(2024, 7, 6),
            cellGroupIDs: ['cg-other'],
          ),
        ],
        memberGroupIds: memberGroupIds,
        memberGroups: memberGroups,
      );

      expect(rows.map((r) => r.head.id).toList(), ['m1', 'm2']);
      expect(rows.first.group.id, 'cg-a');
      expect(rows.last.group.id, 'cg-b');
    });

    test('meetingsForMember picks member group when post links multiple groups', () {
      final alpha = group(id: 'cg-a', name: 'Alpha');
      final beta = group(id: 'cg-b', name: 'Beta');

      final rows = PersonalCellGroupMeetings.meetingsForMember(
        meetings: [
          meeting(
            id: 'joint',
            eventDate: DateTime(2024, 7, 5),
            cellGroupIDs: ['cg-b', 'cg-a'],
          ),
        ],
        memberGroupIds: {'cg-a', 'cg-b'},
        memberGroups: [alpha, beta],
      );

      expect(rows.length, 1);
      expect(rows.first.group.id, 'cg-a');
    });

    test('meetingsForMember ignores heads without eventDate', () {
      final alpha = group(id: 'cg-a', name: 'Alpha');
      final head = EventHead(id: 'no-date', title: 'TBD');
      head.setCellGroupIDs(['cg-a']);

      final rows = PersonalCellGroupMeetings.meetingsForMember(
        meetings: [head],
        memberGroupIds: {'cg-a'},
        memberGroups: [alpha],
      );

      expect(rows, isEmpty);
    });

    test('primaryLeaderForGroup returns first resolved leader', () {
      final g = group(id: 'cg-a', name: 'Alpha', leaderUserIds: ['u2', 'u1']);
      final users = [
        User(id: 'u1', forname: 'Ann', surname: 'Lee'),
        User(id: 'u2', forname: 'Bob', surname: 'Smith'),
      ];

      expect(
        PersonalCellGroupMeetings.primaryLeaderForGroup(group: g, users: users)?.id,
        'u2',
      );
    });

    test('leaderDisplayName falls back when leader unresolved', () {
      final g = group(id: 'cg-a', name: 'Alpha', leaderUserIds: ['missing']);

      expect(
        PersonalCellGroupMeetings.leaderDisplayName(
          group: g,
          users: const [],
          fallbackLabel: 'Leader TBC',
        ),
        'Leader TBC',
      );
    });

    test('leaderDisplayName uses fullname when leader resolved', () {
      final g = group(id: 'cg-a', name: 'Alpha', leaderUserIds: ['u1']);
      final users = [User(id: 'u1', forname: 'Ann', surname: 'Lee')];

      expect(
        PersonalCellGroupMeetings.leaderDisplayName(
          group: g,
          users: users,
          fallbackLabel: 'Leader TBC',
        ),
        'Ann Lee',
      );
    });
  });
}
