import 'package:ctrim_app/models/cell_group.dart';
import 'package:ctrim_app/models/cell_group_roster.dart';
import 'package:ctrim_app/models/user.dart';
import 'package:ctrim_app/utility/cell_group_roster_cache.dart';
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

  group('CellGroupRosterCache.groupsForUser', () {
    final member = _user(id: '10');
    final leader = _user(id: '20', authID: 'auth-leader');

    final alpha = CellGroup(
      id: '1',
      name: 'Alpha Group',
      leaderUserIds: const ['20'],
      leaderAuthIds: const ['auth-leader'],
      meetingWeekday: DateTime.tuesday,
      meetingTime: '19:30',
    );

    final beta = CellGroup(
      id: '2',
      name: 'Beta Group',
    );

    final archived = CellGroup(
      id: '3',
      name: 'Old Group',
      status: CellGroupStatus.archived,
    );

    test('includes active roster member and listed leader', () {
      CellGroupRosterCache.put(
        '2',
        CellGroupRoster(members: [
          CellGroupRosterMember(userId: '10'),
        ]),
      );

      final groups = CellGroupRosterCache.groupsForUser(
        user: member,
        catalogue: [alpha, beta, archived],
      );

      expect(groups.map((g) => g.id), ['2']);
    });

    test('includes leader from head doc without roster row', () {
      final groups = CellGroupRosterCache.groupsForUser(
        user: leader,
        catalogue: [alpha, beta],
      );

      expect(groups.map((g) => g.id), ['1']);
    });

    test('matches leader via AuthID when user id differs', () {
      final authLeader = _user(id: '99', authID: 'auth-leader');

      final groups = CellGroupRosterCache.groupsForUser(
        user: authLeader,
        catalogue: [alpha],
      );

      expect(groups.map((g) => g.id), ['1']);
    });

    test('ignores inactive roster rows and archived groups', () {
      CellGroupRosterCache.put(
        '2',
        CellGroupRoster(members: [
          CellGroupRosterMember(
            userId: '10',
            status: CellGroupMemberStatus.inactive,
          ),
        ]),
      );

      final groups = CellGroupRosterCache.groupsForUser(
        user: member,
        catalogue: [beta, archived],
      );

      expect(groups, isEmpty);
    });

    test('sorts matches by group name', () {
      CellGroupRosterCache.put(
        '1',
        CellGroupRoster(members: [
          CellGroupRosterMember(userId: '10'),
        ]),
      );
      CellGroupRosterCache.put(
        '2',
        CellGroupRoster(members: [
          CellGroupRosterMember(userId: '10'),
        ]),
      );

      final groups = CellGroupRosterCache.groupsForUser(
        user: member,
        catalogue: [beta, alpha],
      );

      expect(groups.map((g) => g.name), ['Alpha Group', 'Beta Group']);
    });
  });

  group('CellGroupRosterCache.ensureLoaded', () {
    test('invalidate clears one group or all', () {
      CellGroupRosterCache.put('1', CellGroupRoster());
      CellGroupRosterCache.put('2', CellGroupRoster());

      CellGroupRosterCache.invalidate('1');
      expect(CellGroupRosterCache.isLoaded('1'), false);
      expect(CellGroupRosterCache.isLoaded('2'), true);

      CellGroupRosterCache.invalidate();
      expect(CellGroupRosterCache.isLoaded('2'), false);
    });
  });
}
