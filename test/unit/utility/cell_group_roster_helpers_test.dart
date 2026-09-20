import 'package:ctrim_app/models/cell_group.dart';
import 'package:ctrim_app/models/cell_group_roster.dart';
import 'package:ctrim_app/models/user.dart';
import 'package:ctrim_app/utility/cell_group_roster_cache.dart';
import 'package:ctrim_app/utility/cell_group_roster_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

User _user({required String id, String authID = ''}) {
  return User(
    id: id,
    forname: 'Test',
    surname: 'User',
    authID: authID,
  );
}

void main() {
  tearDown(CellGroupRosterCache.resetForTesting);

  final leader = _user(id: '20', authID: 'auth-leader');
  final coLeader = _user(id: '21');
  final outsider = _user(id: '99');

  final alpha = CellGroup(
    id: '1',
    name: 'Alpha Group',
    leaderUserIds: const ['20', '21'],
    leaderAuthIds: const ['auth-leader'],
  );
  final archived = CellGroup(
    id: '3',
    name: 'Old Group',
    leaderUserIds: const ['20'],
    status: CellGroupStatus.archived,
  );

  group('CellGroupRosterHelpers.linkedRosterUsersByGroupId', () {
    test('returns empty for guests without reading rosters', () async {
      CellGroupRosterCache.put(
        '1',
        CellGroupRoster(members: [CellGroupRosterMember(userId: '10')]),
      );
      final result = await CellGroupRosterHelpers.linkedRosterUsersByGroupId(
        groups: [alpha],
        allUsers: [_user(id: '10')],
        isGuest: true,
      );
      expect(result, isEmpty);
    });

    test('maps active linked members to users, capped', () async {
      CellGroupRosterCache.put(
        '1',
        CellGroupRoster(members: [
          CellGroupRosterMember(userId: '10'),
          CellGroupRosterMember(userId: '11'),
          CellGroupRosterMember(
            userId: '12',
            status: CellGroupMemberStatus.inactive,
          ),
        ]),
      );
      final ten = _user(id: '10');
      final eleven = _user(id: '11');
      final result = await CellGroupRosterHelpers.linkedRosterUsersByGroupId(
        groups: [alpha, archived],
        allUsers: [ten, eleven, _user(id: '12')],
        isGuest: false,
        maxFaces: 1,
      );
      expect(result.keys, ['1']);
      expect(result['1']!.map((u) => u.id), ['10']);
    });
  });

  group('CellGroupRosterHelpers.activeLinkedUserIdsLedBy', () {
    test('includes active roster members of groups the actor leads', () {
      CellGroupRosterCache.put(
        '1',
        CellGroupRoster(members: [
          CellGroupRosterMember(userId: '10'),
          CellGroupRosterMember(
            userId: '11',
            status: CellGroupMemberStatus.inactive,
          ),
        ]),
      );
      CellGroupRosterCache.put(
        '3',
        CellGroupRoster(members: [
          CellGroupRosterMember(userId: '12'),
        ]),
      );

      expect(
        CellGroupRosterHelpers.activeLinkedUserIdsLedBy(
          actor: leader,
          catalogue: [alpha, archived],
        ),
        {'10'},
      );
      expect(
        CellGroupRosterHelpers.activeLinkedUserIdsLedBy(
          actor: coLeader,
          catalogue: [alpha, archived],
        ),
        {'10'},
      );
      expect(
        CellGroupRosterHelpers.activeLinkedUserIdsLedBy(
          actor: outsider,
          catalogue: [alpha],
        ),
        isEmpty,
      );
    });
  });

  group('CellGroupRosterHelpers.actorLeadsGroupContainingUser', () {
    test('true for any listed leader of a containing group', () {
      CellGroupRosterCache.put(
        '1',
        CellGroupRoster(members: [
          CellGroupRosterMember(userId: '10'),
        ]),
      );

      expect(
        CellGroupRosterHelpers.actorLeadsGroupContainingUser(
          actor: leader,
          targetUserId: '10',
          catalogue: [alpha],
        ),
        isTrue,
      );
      expect(
        CellGroupRosterHelpers.actorLeadsGroupContainingUser(
          actor: coLeader,
          targetUserId: '10',
          catalogue: [alpha],
        ),
        isTrue,
      );
      expect(
        CellGroupRosterHelpers.actorLeadsGroupContainingUser(
          actor: outsider,
          targetUserId: '10',
          catalogue: [alpha],
        ),
        isFalse,
      );
    });
  });
}
