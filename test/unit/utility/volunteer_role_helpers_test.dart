import 'package:ctrim_app/models/cell_group.dart';
import 'package:ctrim_app/models/user.dart';
import 'package:ctrim_app/utility/volunteer_role_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

User _user({
  required String id,
  bool isLeader = false,
  bool isAreaAdmin = false,
  String authID = '',
}) {
  return User(
    id: id,
    forname: 'A',
    surname: 'B',
    isLeader: isLeader,
    isAreaAdmin: isAreaAdmin,
    authID: authID,
  );
}

void main() {
  group('CellGroupLeaderIndex', () {
    test('includes leaders from active and paused groups', () {
      final groups = [
        CellGroup(
            id: 'a',
            name: 'Active',
            leaderUserIds: ['u1'],
            leaderAuthIds: ['auth-1']),
        CellGroup(
          id: 'p',
          name: 'Paused',
          status: CellGroupStatus.paused,
          leaderUserIds: ['u2'],
        ),
      ];
      final index = CellGroupLeaderIndex.fromGroups(groups);

      expect(index.contains(_user(id: 'u1')), isTrue);
      expect(index.contains(_user(id: 'u2')), isTrue);
      expect(index.contains(_user(id: 'u3')), isFalse);
    });

    test('excludes archived group leaders', () {
      final groups = [
        CellGroup(
          id: 'x',
          name: 'Archived',
          status: CellGroupStatus.archived,
          leaderUserIds: ['u1'],
        ),
      ];
      final index = CellGroupLeaderIndex.fromGroups(groups);

      expect(index.contains(_user(id: 'u1')), isFalse);
      expect(index.isEmpty, isTrue);
    });

    test('matches by auth id when user id is not listed', () {
      final groups = [
        CellGroup(id: 'a', name: 'Active', leaderAuthIds: ['auth-9']),
      ];
      final index = CellGroupLeaderIndex.fromGroups(groups);

      expect(index.contains(_user(id: 'other', authID: 'auth-9')), isTrue);
      expect(index.contains(_user(id: 'other', authID: '')), isFalse);
    });
  });

  group('VolunteerRoleHelpers', () {
    final groups = [
      CellGroup(id: 'a', name: 'Active', leaderUserIds: ['cg1']),
    ];
    final index = CellGroupLeaderIndex.fromGroups(groups);

    test('rolesFor shows Admin instead of Leader when both flags apply', () {
      final roles = VolunteerRoleHelpers.rolesFor(
        user: _user(id: 'cg1', isLeader: true, isAreaAdmin: true),
        cellGroupLeaders: index,
      );

      expect(
        roles,
        {
          VolunteerRoleKind.areaAdmin,
          VolunteerRoleKind.cellGroupLeader,
        },
      );
    });

    test('rolesFor shows Leader when the user is not an admin', () {
      final roles = VolunteerRoleHelpers.rolesFor(
        user: _user(id: 'l1', isLeader: true),
        cellGroupLeaders: index,
      );

      expect(roles, {VolunteerRoleKind.leader});
    });

    test('empty role filter matches everyone', () {
      expect(
        VolunteerRoleHelpers.userMatchesRoleFilter(
          user: _user(id: 'plain'),
          selected: {},
          cellGroupLeaders: index,
        ),
        isTrue,
      );
    });

    test('Leaders filter includes area admins', () {
      final admin = _user(id: 'a1', isAreaAdmin: true);
      expect(
        VolunteerRoleHelpers.userMatchesRoleFilter(
          user: admin,
          selected: {VolunteerRoleKind.leader},
          cellGroupLeaders: index,
        ),
        isTrue,
      );
    });

    test('Admins filter excludes leaders who are not admins', () {
      final leader = _user(id: 'l1', isLeader: true);
      expect(
        VolunteerRoleHelpers.userMatchesRoleFilter(
          user: leader,
          selected: {VolunteerRoleKind.areaAdmin},
          cellGroupLeaders: index,
        ),
        isFalse,
      );
    });

    test('role filter is OR across selected roles', () {
      final leader = _user(id: 'l1', isLeader: true);
      final cgLeader = _user(id: 'cg1');
      final none = _user(id: 'plain');
      const selected = {
        VolunteerRoleKind.leader,
        VolunteerRoleKind.cellGroupLeader
      };

      expect(
        VolunteerRoleHelpers.userMatchesRoleFilter(
          user: leader,
          selected: selected,
          cellGroupLeaders: index,
        ),
        isTrue,
      );
      expect(
        VolunteerRoleHelpers.userMatchesRoleFilter(
          user: cgLeader,
          selected: selected,
          cellGroupLeaders: index,
        ),
        isTrue,
      );
      expect(
        VolunteerRoleHelpers.userMatchesRoleFilter(
          user: none,
          selected: selected,
          cellGroupLeaders: index,
        ),
        isFalse,
      );
    });

    test('toggleRole keeps Leader and Admin mutually exclusive', () {
      var selected = <VolunteerRoleKind>{};
      selected = VolunteerRoleHelpers.toggleRole(
        current: selected,
        role: VolunteerRoleKind.leader,
      );
      expect(selected, {VolunteerRoleKind.leader});

      selected = VolunteerRoleHelpers.toggleRole(
        current: selected,
        role: VolunteerRoleKind.areaAdmin,
      );
      expect(selected, {VolunteerRoleKind.areaAdmin});

      selected = VolunteerRoleHelpers.toggleRole(
        current: selected,
        role: VolunteerRoleKind.cellGroupLeader,
      );
      expect(
        selected,
        {VolunteerRoleKind.areaAdmin, VolunteerRoleKind.cellGroupLeader},
      );
    });
  });
}
