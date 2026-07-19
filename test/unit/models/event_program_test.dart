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

      test('toJson omits timestamps for roles without start/end', () {
        final program = EventProgram();
        program.addRole(uids: ['user-1'], title: 'Open slot', start: null, end: null, id: 3000);

        final json = program.toJson();
        final role = (json['Roles'] as List).first as Map<String, dynamic>;

        expect(role['start'], isNull);
        expect(role['end'], isNull);
        expect(role['title'], 'Open slot');
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

    group('cascade timing', () {
      EventProgram buildSequentialProgram() {
        final program = EventProgram();
        program.addRole(
          uids: [],
          title: 'Welcome',
          start: DateTime(2024, 6, 15, 10, 0),
          end: DateTime(2024, 6, 15, 10, 15),
          id: 1,
        );
        program.addRole(
          uids: [],
          title: 'Worship',
          start: DateTime(2024, 6, 15, 10, 15),
          end: DateTime(2024, 6, 15, 10, 45),
          id: 2,
        );
        program.addRole(
          uids: [],
          title: 'Message',
          start: DateTime(2024, 6, 15, 10, 45),
          end: DateTime(2024, 6, 15, 11, 30),
          id: 3,
        );
        return program;
      }

      test('countRolesStartingAtOrAfter excludes the edited role', () {
        final program = buildSequentialProgram();
        expect(
          program.countRolesStartingAtOrAfter(DateTime(2024, 6, 15, 10, 15), excludeRoleId: 1),
          2,
        );
      });

      test('updateRoleTiming with shiftFollowing pushes later items', () {
        final program = buildSequentialProgram();
        program.updateRoleTiming(
          roleId: 1,
          newStart: DateTime(2024, 6, 15, 10, 0),
          newEnd: DateTime(2024, 6, 15, 10, 25),
          shiftFollowing: true,
        );

        expect(program.roles[0]['end'], DateTime(2024, 6, 15, 10, 25));
        expect(program.roles[1]['start'], DateTime(2024, 6, 15, 10, 25));
        expect(program.roles[1]['end'], DateTime(2024, 6, 15, 10, 55));
        expect(program.roles[2]['start'], DateTime(2024, 6, 15, 10, 55));
        expect(program.roles[2]['end'], DateTime(2024, 6, 15, 11, 40));
      });

      test('updateRoleTiming without shiftFollowing leaves later items alone', () {
        final program = buildSequentialProgram();
        program.updateRoleTiming(
          roleId: 1,
          newStart: DateTime(2024, 6, 15, 10, 0),
          newEnd: DateTime(2024, 6, 15, 10, 25),
          shiftFollowing: false,
        );

        expect(program.roles[0]['end'], DateTime(2024, 6, 15, 10, 25));
        expect(program.roles[1]['start'], DateTime(2024, 6, 15, 10, 15));
        expect(program.roles[2]['start'], DateTime(2024, 6, 15, 10, 45));
      });

      test('updateRoleTiming does not shift overlapping parallel roles', () {
        final program = buildSequentialProgram();
        program.addRole(
          uids: [],
          title: 'Tech',
          start: DateTime(2024, 6, 15, 10, 0),
          end: DateTime(2024, 6, 15, 11, 30),
          id: 4,
        );

        program.updateRoleTiming(
          roleId: 1,
          newStart: DateTime(2024, 6, 15, 10, 0),
          newEnd: DateTime(2024, 6, 15, 10, 25),
          shiftFollowing: true,
        );

        final tech = program.roles.firstWhere((role) => role['id'] == 4);
        expect(tech['start'], DateTime(2024, 6, 15, 10, 0));
        expect(tech['end'], DateTime(2024, 6, 15, 11, 30));
      });

      test('applyInsertShift pushes items at or after the insert start', () {
        final program = buildSequentialProgram();
        program.applyInsertShift(
          start: DateTime(2024, 6, 15, 10, 15),
          end: DateTime(2024, 6, 15, 10, 30),
          shiftFollowing: true,
        );

        expect(program.roles[1]['title'], 'Worship');
        expect(program.roles[1]['start'], DateTime(2024, 6, 15, 10, 30));
        expect(program.roles[2]['start'], DateTime(2024, 6, 15, 11, 0));
      });

      test('moveRoleInOrder swaps adjacent items and preserves durations', () {
        final program = buildSequentialProgram();
        final moved = program.moveRoleInOrder(2, -1);

        expect(moved, true);
        expect(program.roles[0]['title'], 'Worship');
        expect(program.roles[0]['start'], DateTime(2024, 6, 15, 10, 0));
        expect(program.roles[0]['end'], DateTime(2024, 6, 15, 10, 30));
        expect(program.roles[1]['title'], 'Welcome');
        expect(program.roles[1]['start'], DateTime(2024, 6, 15, 10, 30));
        expect(program.roles[1]['end'], DateTime(2024, 6, 15, 10, 45));
        expect(program.roles[2]['start'], DateTime(2024, 6, 15, 10, 45));
      });

      test('moveRoleInOrder returns false at list edges', () {
        final program = buildSequentialProgram();
        expect(program.moveRoleInOrder(1, -1), false);
        expect(program.moveRoleInOrder(3, 1), false);
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
