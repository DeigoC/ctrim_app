import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ctrim_app/models/event/event_attendance.dart';

void main() {
  group('InterestedEntry', () {
    test('constructor and toJson round-trip fields', () {
      final ts = DateTime(2026, 7, 20, 12);
      final entry = InterestedEntry(
        authId: 'auth-1',
        displayName: 'Jane Doe',
        userId: 'u-1',
        ts: ts,
      );

      expect(entry.authId, 'auth-1');
      expect(entry.displayName, 'Jane Doe');
      expect(entry.userId, 'u-1');
      expect(entry.ts, ts);

      final json = entry.toJson();
      expect(json['displayName'], 'Jane Doe');
      expect(json['userId'], 'u-1');
      expect(json['ts'], isA<Timestamp>());
    });

    test('fromMap uses authId key and defaults displayName', () {
      final entry = InterestedEntry.fromMap('auth-2', {
        'userId': null,
        'ts': Timestamp.fromDate(DateTime(2026, 1, 1)),
      });

      expect(entry.authId, 'auth-2');
      expect(entry.displayName, 'Signed-in user');
      expect(entry.userId, isNull);
    });
  });

  group('AttendeeEntry', () {
    test('user factory sets stable id', () {
      final entry = AttendeeEntry.user(
        userId: '42',
        displayName: 'Bob',
        addedBy: '1',
      );

      expect(entry.id, 'user_42');
      expect(entry.isUser, true);
      expect(entry.userId, '42');
      expect(entry.displayName, 'Bob');
    });

    test('external factory stores name and note', () {
      final entry = AttendeeEntry.external(
        name: 'Maria Guest',
        addedBy: '1',
        note: 'friend of Bob',
        id: 'ext_fixed',
      );

      expect(entry.id, 'ext_fixed');
      expect(entry.isExternal, true);
      expect(entry.name, 'Maria Guest');
      expect(entry.note, 'friend of Bob');
      expect(entry.displayName, 'Maria Guest');
    });

    test('fromMap / toJson preserve type', () {
      final ts = DateTime(2026, 3, 1);
      final entry = AttendeeEntry.fromMap({
        'id': 'user_9',
        'type': 'user',
        'userId': '9',
        'name': null,
        'note': null,
        'displayName': 'Ada',
        'addedBy': '1',
        'ts': Timestamp.fromDate(ts),
      });

      final json = entry.toJson();
      expect(json['type'], 'user');
      expect(json['userId'], '9');
      expect(json['displayName'], 'Ada');
    });
  });

  group('EventAttendance', () {
    test('empty defaults', () {
      final attendance = EventAttendance();
      expect(attendance.interestedCount, 0);
      expect(attendance.attendeeCount, 0);
      expect(attendance.expectedCount, 0);
      expect(attendance.hasInterest('x'), false);
    });

    test('put and remove interest', () {
      final attendance = EventAttendance();
      attendance.putInterest(InterestedEntry(authId: 'a1', displayName: 'A'));
      expect(attendance.hasInterest('a1'), true);
      expect(attendance.interestedCount, 1);

      attendance.removeInterest('a1');
      expect(attendance.hasInterest('a1'), false);
    });

    test('addAttendee dedupes registered users', () {
      final attendance = EventAttendance();
      attendance.addAttendee(AttendeeEntry.user(userId: '5', displayName: 'Five', addedBy: '1'));
      attendance.addAttendee(AttendeeEntry.user(userId: '5', displayName: 'Five again', addedBy: '1'));
      expect(attendance.attendeeCount, 1);
    });

    test('expectedUserIds set and query', () {
      final attendance = EventAttendance(expectedUserIds: ['1', '2', '']);
      expect(attendance.expectedCount, 2);
      expect(attendance.hasExpectedUser('1'), true);
      expect(attendance.hasExpectedUser('9'), false);

      attendance.setExpectedUserIds(['2', '2', '3']);
      expect(attendance.expectedUserIds, ['2', '3']);
    });

    test('fromMap parses interested map, attendees, and expectedUserIds', () {
      final attendance = EventAttendance.fromMap({
        'interested': {
          'auth-9': {
            'userId': '9',
            'displayName': 'Nine',
            'ts': Timestamp.fromDate(DateTime(2026, 2, 2)),
          },
        },
        'attendees': [
          {
            'id': 'ext_1',
            'type': 'external',
            'userId': null,
            'name': 'Guest',
            'note': null,
            'displayName': 'Guest',
            'addedBy': '1',
            'ts': Timestamp.fromDate(DateTime(2026, 2, 3)),
          },
        ],
        'expectedUserIds': ['10', '11'],
      });

      expect(attendance.interestedCount, 1);
      expect(attendance.interestFor('auth-9')!.displayName, 'Nine');
      expect(attendance.attendeeCount, 1);
      expect(attendance.attendees.first.isExternal, true);
      expect(attendance.expectedUserIds, ['10', '11']);
    });

    test('toJson shape includes expectedUserIds', () {
      final attendance = EventAttendance(expectedUserIds: ['7']);
      attendance.putInterest(InterestedEntry(authId: 'a', displayName: 'A', ts: DateTime(2026, 1, 1)));
      attendance.addAttendee(AttendeeEntry.external(name: 'G', addedBy: '1', id: 'ext_1', ts: DateTime(2026, 1, 2)));

      final json = attendance.toJson();
      expect(json['interested'], isA<Map>());
      expect((json['interested'] as Map).containsKey('a'), true);
      expect(json['attendees'], isA<List>());
      expect((json['attendees'] as List).length, 1);
      expect(json['expectedUserIds'], ['7']);
    });

    test('interested and attendees getters are unmodifiable', () {
      final attendance = EventAttendance();
      expect(() => attendance.interested['x'] = InterestedEntry(authId: 'x', displayName: 'X'), throwsUnsupportedError);
      expect(
          () => attendance.attendees.add(AttendeeEntry.external(name: 'n', addedBy: '1')), throwsUnsupportedError);
      expect(() => attendance.expectedUserIds.add('1'), throwsUnsupportedError);
    });
  });
}
