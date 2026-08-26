import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ctrim_app/models/cell_group_roster.dart';

void main() {
  group('CellGroupRosterMember', () {
    test('linked user vs free-text', () {
      final linked = CellGroupRosterMember(userId: '7');
      expect(linked.isLinkedUser, true);
      expect(linked.isFreeText, false);

      final freeText = CellGroupRosterMember(displayName: 'Alex Guest');
      expect(freeText.isLinkedUser, false);
      expect(freeText.isFreeText, true);
    });

    test('fromMap / toJson round trip', () {
      final joined = DateTime(2026, 3, 1);
      final member = CellGroupRosterMember.fromMap({
        'UserId': '3',
        'DisplayName': '',
        'Role': CellGroupMemberRole.host,
        'Status': CellGroupMemberStatus.active,
        'JoinedAt': Timestamp.fromDate(joined),
      });

      expect(member.userId, '3');
      expect(member.role, CellGroupMemberRole.host);
      expect(member.joinedAt, joined);

      final json = member.toJson();
      expect(json['UserId'], '3');
      expect(json['Role'], CellGroupMemberRole.host);
      expect(json['JoinedAt'], isA<Timestamp>());
    });

    test('fromMap coerces numeric UserId to string', () {
      final member = CellGroupRosterMember.fromMap({
        'UserId': 42,
        'DisplayName': '',
        'Role': CellGroupMemberRole.member,
        'Status': CellGroupMemberStatus.active,
      });
      expect(member.userId, '42');
      expect(member.isLinkedUser, true);
    });
  });

  group('CellGroupRoster', () {
    test('fromMap parses members and activeCount', () {
      final roster = CellGroupRoster.fromMap({
        'Members': [
          {'UserId': '1', 'DisplayName': '', 'Role': 'member', 'Status': 'active'},
          {'UserId': '', 'DisplayName': 'Sam', 'Role': 'member', 'Status': 'inactive'},
        ],
      });

      expect(roster.members.length, 2);
      expect(roster.activeCount, 1);
      expect(roster.containsUserId('1'), true);
      expect(roster.containsUserId('9'), false);
    });

    test('toJson serializes members', () {
      final roster = CellGroupRoster(members: [
        CellGroupRosterMember(userId: '1'),
        CellGroupRosterMember(displayName: 'Pat'),
      ]);
      final json = roster.toJson();
      expect(json['Members'], hasLength(2));
      expect(json['Members'][0]['UserId'], '1');
      expect(json['Members'][1]['DisplayName'], 'Pat');
    });
  });
}
