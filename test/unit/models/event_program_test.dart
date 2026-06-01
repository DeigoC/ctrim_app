import 'package:flutter_test/flutter_test.dart';

import 'package:ctrim_app/models/event/event_program.dart';

void main() {
  group('EventProgram', () {
    group('constructor', () {
      test('creates with correct default values', () {
        final program = EventProgram();

        expect(program.allDay, false);
        expect(program.online, false);
        expect(program.finishTime, isNull);
        expect(program.address, isNotEmpty);
        expect(program.mapLink, isNotEmpty);
        expect(program.roles, isEmpty);
      });
    });

    group('setters', () {
      test('setAllDay updates allDay', () {
        final program = EventProgram();
        program.setAllDay(true);
        expect(program.allDay, true);
      });

      test('setOnline updates online', () {
        final program = EventProgram();
        program.setOnline(true);
        expect(program.online, true);
      });

      test('setFinishTime updates finishTime', () {
        final program = EventProgram();
        final finish = DateTime(2024, 6, 15, 17, 0);
        program.setFinishTime(finish);
        expect(program.finishTime, finish);
      });

      test('setFinishTime can be set to null', () {
        final program = EventProgram();
        program.setFinishTime(DateTime(2024, 6, 15, 17, 0));
        program.setFinishTime(null);
        expect(program.finishTime, isNull);
      });

      test('setAddress updates address', () {
        final program = EventProgram();
        program.setAddress('123 Main St');
        expect(program.address, '123 Main St');
      });

      test('setMapLink updates mapLink', () {
        final program = EventProgram();
        program.setMapLink('https://maps.example.com');
        expect(program.mapLink, 'https://maps.example.com');
      });
    });

    group('role management', () {
      test('addRole inserts a role', () {
        final program = EventProgram();
        program.addRole(
          uids: ['user-1'],
          title: 'Worship Leader',
          start: DateTime(2024, 6, 15, 10, 0),
          end: DateTime(2024, 6, 15, 11, 0),
          id: 1000,
        );

        expect(program.roles.length, 1);
        expect(program.roles.first['title'], 'Worship Leader');
        expect(program.roles.first['uids'], ['user-1']);
        expect(program.roles.first['id'], 1000);
        expect(program.roles.first['for_guests'], true);
        expect(program.roles.first['detail'], '');
      });

      test('addRole stores forGuests and detail overrides', () {
        final program = EventProgram();
        program.addRole(
          uids: ['user-2'],
          title: 'Greeter',
          start: null,
          end: null,
          id: 2000,
          forGuests: false,
          detail: 'Welcome guests at door',
        );

        expect(program.roles.first['for_guests'], false);
        expect(program.roles.first['detail'], 'Welcome guests at door');
      });

      test('removeRole removes matching role by id', () {
        final program = EventProgram();
        program.addRole(uids: [], title: 'A', start: null, end: null, id: 1);
        program.addRole(uids: [], title: 'B', start: null, end: null, id: 2);

        program.removeRole(1);

        expect(program.roles.length, 1);
        expect(program.roles.first['id'], 2);
      });

      test('clearRoles removes all roles', () {
        final program = EventProgram();
        program.addRole(uids: [], title: 'A', start: null, end: null, id: 1);
        program.addRole(uids: [], title: 'B', start: null, end: null, id: 2);

        program.clearRoles();

        expect(program.roles, isEmpty);
      });

      test('roles getter returns an unmodifiable view', () {
        final program = EventProgram();
        expect(() => program.roles.add({}), throwsUnsupportedError);
      });
    });

    group('orderProgramsByStartTime', () {
      test('sorts roles in ascending start time order', () {
        final program = EventProgram();
        program.addRole(
          uids: [],
          title: 'Second',
          start: DateTime(2024, 6, 15, 12, 0),
          end: DateTime(2024, 6, 15, 13, 0),
          id: 2,
        );
        program.addRole(
          uids: [],
          title: 'First',
          start: DateTime(2024, 6, 15, 10, 0),
          end: DateTime(2024, 6, 15, 11, 0),
          id: 1,
        );

        program.orderProgramsByStartTime();

        expect(program.roles[0]['title'], 'First');
        expect(program.roles[1]['title'], 'Second');
      });
    });

    group('toString', () {
      test('includes finish time when set', () {
        final program = EventProgram();
        program.setFinishTime(DateTime(2024, 6, 15, 17, 0));
        expect(program.toString(), contains('Finish datetime is'));
      });

      test('says "No finish datetime" when finishTime is null', () {
        final program = EventProgram();
        expect(program.toString(), contains('No finish datetime'));
      });
    });
  });
}
