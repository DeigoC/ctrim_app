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
      expect(group.media, isEmpty);
      expect(group.keyGraphicSrc, isNull);
      expect(group.hasKeyGraphic, false);
    });

    test('fromMap parses Firestore fields', () {
      final created = DateTime(2026, 8, 1, 12);
      final group = CellGroup.fromMap('cg1', {
        'Name': 'East Side',
        'Summary': 'Weekly fellowship',
        'Location': 'Belfast',
        'LeaderUserIds': ['7', '8'],
        'LeaderAuthIds': ['auth-a'],
        'Media': [
          {'src': 'drive/photo1', 'type': 'img', 'title': 'Cover'},
          {'src': 'drive/photo2', 'type': 'img', 'title': ''},
        ],
        'KeyGraphicSrc': 'drive/photo1',
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
      expect(group.media, hasLength(2));
      expect(group.keyGraphicSrc, 'drive/photo1');
      expect(group.hasKeyGraphic, true);
    });

    test('fromMap clears orphan KeyGraphicSrc', () {
      final group = CellGroup.fromMap('cg1', {
        'Name': 'CG',
        'Media': [
          {'src': 'drive/a', 'type': 'img'},
        ],
        'KeyGraphicSrc': 'drive/missing',
      });
      expect(group.keyGraphicSrc, isNull);
    });

    test('toJson writes PascalCase keys', () {
      final group = CellGroup(
        id: '1',
        name: 'CG',
        leaderUserIds: ['2'],
        leaderAuthIds: ['auth-2'],
        media: [
          {'src': 'drive/cover', 'type': 'img', 'title': 'Group'},
        ],
        keyGraphicSrc: 'drive/cover',
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
      expect(json['Media'], hasLength(1));
      expect(json['KeyGraphicSrc'], 'drive/cover');
    });

    test('media helpers enforce capacity and key graphic sync', () {
      final group = CellGroup(id: '1', name: 'CG');
      expect(
        group.addMediaItem({'src': 'a', 'type': 'img'}),
        isTrue,
      );
      expect(group.setKeyGraphicSrc('a'), isTrue);
      expect(group.keyGraphicSrc, 'a');

      expect(group.setKeyGraphicSrc('missing'), isFalse);
      expect(group.keyGraphicSrc, 'a');

      group.removeMediaItem('a');
      expect(group.media, isEmpty);
      expect(group.keyGraphicSrc, isNull);

      for (var i = 0; i < CellGroup.maxMediaItems; i++) {
        expect(group.addMediaItem({'src': 'src-$i', 'type': 'img'}), isTrue);
      }
      expect(group.addMediaItem({'src': 'overflow', 'type': 'img'}), isFalse);
      expect(group.addMediaItem({'src': 'src-0', 'type': 'img'}), isFalse);
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
