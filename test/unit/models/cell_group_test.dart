import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ctrim_app/models/cell_group.dart';

void main() {
  group('CellGroup', () {
    test('creates with defaults', () {
      final group = CellGroup(id: '1', name: 'North Belfast');

      expect(group.id, '1');
      expect(group.name, 'North Belfast');
      expect(group.summary, '');
      expect(group.location, 'Belfast');
      expect(group.leaderUserIds, isEmpty);
      expect(group.leaderAuthIds, isEmpty);
      expect(group.memberCount, 0);
      expect(group.status, CellGroupStatus.active);
      expect(group.isActive, true);
      expect(group.meetingWeekday, isNull);
      expect(group.meetingTime, '');
      expect(group.cadenceLabel, '');
    });

    test('fromMap parses Firestore fields', () {
      final created = DateTime(2026, 8, 1, 12);
      final group = CellGroup.fromMap('cg1', {
        'Name': 'East Side',
        'Summary': 'Weekly fellowship',
        'Location': 'Belfast',
        'LeaderUserIds': ['7', '8'],
        'LeaderAuthIds': ['auth-a'],
        'MemberCount': 12,
        'Status': CellGroupStatus.paused,
        'MeetingWeekday': DateTime.tuesday,
        'MeetingTime': '19:30',
        'CreatedByUserID': '1',
        'CreatedAt': Timestamp.fromDate(created),
        'UpdatedAt': Timestamp.fromDate(created),
      });

      expect(group.id, 'cg1');
      expect(group.name, 'East Side');
      expect(group.summary, 'Weekly fellowship');
      expect(group.leaderUserIds, ['7', '8']);
      expect(group.leaderAuthIds, ['auth-a']);
      expect(group.memberCount, 12);
      expect(group.isPaused, true);
      expect(group.meetingWeekday, DateTime.tuesday);
      expect(group.meetingTime, '19:30');
      expect(group.cadenceLabel, 'Tuesday · 19:30');
      expect(group.isLeaderUser('7'), true);
      expect(group.isLeaderAuth('auth-a'), true);
      expect(group.createdByUserID, '1');
    });

    test('toJson writes PascalCase keys', () {
      final group = CellGroup(
        id: '1',
        name: 'CG',
        leaderUserIds: ['2'],
        leaderAuthIds: ['auth-2'],
        meetingWeekday: DateTime.friday,
        meetingTime: '20:00',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 2),
      );
      final json = group.toJson();

      expect(json['Name'], 'CG');
      expect(json['LeaderUserIds'], ['2']);
      expect(json['LeaderAuthIds'], ['auth-2']);
      expect(json['MeetingWeekday'], DateTime.friday);
      expect(json['MeetingTime'], '20:00');
      expect(json['Status'], CellGroupStatus.active);
      expect(json['CreatedAt'], isA<Timestamp>());
    });

    test('setLeaders filters empty auth ids', () {
      final group = CellGroup(id: '1', name: 'CG');
      group.setLeaders(userIds: ['1', '2'], authIds: ['auth-1', '', 'auth-2']);
      expect(group.leaderUserIds, ['1', '2']);
      expect(group.leaderAuthIds, ['auth-1', 'auth-2']);
    });

    test('cadenceLabel handles partial fields', () {
      final weekdayOnly = CellGroup(id: '1', name: 'A', meetingWeekday: DateTime.monday);
      expect(weekdayOnly.cadenceLabel, 'Monday');

      final timeOnly = CellGroup(id: '2', name: 'B', meetingTime: '18:00');
      expect(timeOnly.cadenceLabel, '18:00');
    });
  });
}
