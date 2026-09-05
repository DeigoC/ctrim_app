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

      test('hasLocationLaunchUrl is false when map link cleared', () {
        final program = EventProgram();
        program.setMapLink('');
        expect(program.hasLocationLaunchUrl, false);
      });

      test('hasLocationLaunchUrl uses address for online events', () {
        final program = EventProgram();
        program.setOnline(true);
        program.setAddress('');
        expect(program.hasLocationLaunchUrl, false);
        program.setAddress('https://zoom.us/j/123');
        expect(program.hasLocationLaunchUrl, true);
        expect(program.locationLaunchUrl, 'https://zoom.us/j/123');
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

      test('ensureUniqueRoleIds reassigns later duplicates and keeps the first',
          () {
        final program = EventProgram();
        program.addRole(uids: [], title: 'Tithes', start: null, end: null, id: 10);
        program.addRole(uids: [], title: 'Song', start: null, end: null, id: 10);
        program.addRole(uids: [], title: 'Prayer', start: null, end: null, id: 10);
        program.addRole(uids: [], title: 'Eating', start: null, end: null, id: 11);

        expect(program.ensureUniqueRoleIds(), isTrue);
        expect(program.roles[0]['id'], 10);
        expect(program.roles[3]['id'], 11);
        expect(
          program.roles.map((role) => role['id']).toSet().length,
          program.roles.length,
        );
        expect(program.roles[1]['id'], isNot(10));
        expect(program.roles[1]['id'], isNot(11));
        expect(program.ensureUniqueRoleIds(), isFalse);
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

      test('keeps roles without a start time at the end', () {
        final program = EventProgram();
        program.addRole(
          uids: [],
          title: 'Untimed',
          start: null,
          end: null,
          id: 2,
        );
        program.addRole(
          uids: [],
          title: 'Timed',
          start: DateTime(2024, 6, 15, 10, 0),
          end: DateTime(2024, 6, 15, 11, 0),
          id: 1,
        );

        program.orderProgramsByStartTime();

        expect(program.roles[0]['title'], 'Timed');
        expect(program.roles[1]['title'], 'Untimed');
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

      test('scheduleLayoutSignature changes when role timing changes', () {
        final program = buildSequentialProgram();
        final before = program.scheduleLayoutSignature;

        program.updateRoleTiming(
          roleId: 1,
          newStart: DateTime(2024, 6, 15, 10, 0),
          newEnd: DateTime(2024, 6, 15, 10, 25),
          shiftFollowing: false,
        );

        expect(program.scheduleLayoutSignature, isNot(before));
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

      test('rebaseRolesToCalendarDate keeps clock times on the new day', () {
        final program = buildSequentialProgram();
        program.rebaseRolesToCalendarDate(
          oldDay: DateTime(2024, 6, 15, 9, 0),
          newDay: DateTime(2024, 6, 22, 9, 0),
        );

        expect(program.roles[0]['start'], DateTime(2024, 6, 22, 10, 0));
        expect(program.roles[0]['end'], DateTime(2024, 6, 22, 10, 15));
        expect(program.roles[1]['start'], DateTime(2024, 6, 22, 10, 15));
        expect(program.roles[2]['end'], DateTime(2024, 6, 22, 11, 30));
      });

      test('rebaseRolesToCalendarDate is a no-op for the same calendar day', () {
        final program = buildSequentialProgram();
        program.rebaseRolesToCalendarDate(
          oldDay: DateTime(2024, 6, 15, 9, 0),
          newDay: DateTime(2024, 6, 15, 18, 30),
        );

        expect(program.roles[0]['start'], DateTime(2024, 6, 15, 10, 0));
        expect(program.roles[2]['end'], DateTime(2024, 6, 15, 11, 30));
      });

      group('moveRoleToStart', () {
        test('parallel keeps the duration and leaves other roles alone', () {
          final program = buildSequentialProgram();
          final moved = program.moveRoleToStart(
            roleId: 3,
            newStart: DateTime(2024, 6, 15, 10, 0),
            mode: ProgramShiftMode.parallel,
          );

          expect(moved, true);
          final message =
              program.roles.firstWhere((role) => role['id'] == 3);
          expect(message['start'], DateTime(2024, 6, 15, 10, 0));
          expect(message['end'], DateTime(2024, 6, 15, 10, 45));

          final welcome = program.roles.firstWhere((role) => role['id'] == 1);
          final worship = program.roles.firstWhere((role) => role['id'] == 2);
          expect(welcome['start'], DateTime(2024, 6, 15, 10, 0));
          expect(worship['start'], DateTime(2024, 6, 15, 10, 15));
        });

        test('cascade pushes the roles it lands on down the chain', () {
          final program = buildSequentialProgram();
          program.moveRoleToStart(
            roleId: 3,
            newStart: DateTime(2024, 6, 15, 10, 0),
            mode: ProgramShiftMode.cascade,
          );

          final message =
              program.roles.firstWhere((role) => role['id'] == 3);
          final welcome = program.roles.firstWhere((role) => role['id'] == 1);
          final worship = program.roles.firstWhere((role) => role['id'] == 2);

          expect(message['start'], DateTime(2024, 6, 15, 10, 0));
          expect(message['end'], DateTime(2024, 6, 15, 10, 45));
          // Welcome starts when the message finishes, worship follows it.
          expect(welcome['start'], DateTime(2024, 6, 15, 10, 45));
          expect(welcome['end'], DateTime(2024, 6, 15, 11, 0));
          expect(worship['start'], DateTime(2024, 6, 15, 11, 0));
          expect(worship['end'], DateTime(2024, 6, 15, 11, 30));
        });

        test('cascade stops pushing once an item already fits', () {
          final program = buildSequentialProgram();
          program.addRole(
            uids: [],
            title: 'Fellowship',
            start: DateTime(2024, 6, 15, 13, 0),
            end: DateTime(2024, 6, 15, 14, 0),
            id: 4,
          );

          program.moveRoleToStart(
            roleId: 1,
            newStart: DateTime(2024, 6, 15, 10, 30),
            mode: ProgramShiftMode.cascade,
          );

          final fellowship =
              program.roles.firstWhere((role) => role['id'] == 4);
          expect(fellowship['start'], DateTime(2024, 6, 15, 13, 0));
          expect(fellowship['end'], DateTime(2024, 6, 15, 14, 0));
        });

        test('cascade leaves a long role that started earlier in place', () {
          final program = buildSequentialProgram();
          program.addRole(
            uids: [],
            title: 'Technical Sound',
            start: DateTime(2024, 6, 15, 9, 0),
            end: DateTime(2024, 6, 15, 12, 0),
            id: 4,
          );

          program.moveRoleToStart(
            roleId: 1,
            newStart: DateTime(2024, 6, 15, 10, 30),
            mode: ProgramShiftMode.cascade,
          );

          final sound = program.roles.firstWhere((role) => role['id'] == 4);
          expect(sound['start'], DateTime(2024, 6, 15, 9, 0));
          expect(sound['end'], DateTime(2024, 6, 15, 12, 0));
        });

        test('moving earlier does not drag later roles backwards', () {
          final program = buildSequentialProgram();
          program.moveRoleToStart(
            roleId: 1,
            newStart: DateTime(2024, 6, 15, 9, 0),
            mode: ProgramShiftMode.cascade,
          );

          final worship = program.roles.firstWhere((role) => role['id'] == 2);
          expect(worship['start'], DateTime(2024, 6, 15, 10, 15));
        });

        test('roles stay sorted by start after a move', () {
          final program = buildSequentialProgram();
          program.moveRoleToStart(
            roleId: 3,
            newStart: DateTime(2024, 6, 15, 9, 0),
            mode: ProgramShiftMode.parallel,
          );

          expect(program.roles.first['id'], 3);
          expect(program.roles.last['id'], 2);
        });

        test('returns false for an unknown or unmoved role', () {
          final program = buildSequentialProgram();

          expect(
            program.moveRoleToStart(
              roleId: 99,
              newStart: DateTime(2024, 6, 15, 10, 0),
              mode: ProgramShiftMode.cascade,
            ),
            false,
          );
          expect(
            program.moveRoleToStart(
              roleId: 1,
              newStart: DateTime(2024, 6, 15, 10, 0),
              mode: ProgramShiftMode.cascade,
            ),
            false,
          );
        });

        test('returns false when the role has no timing', () {
          final program = EventProgram();
          program.addRole(
            uids: [],
            title: 'Untimed',
            start: null,
            end: null,
            id: 1,
          );

          expect(
            program.moveRoleToStart(
              roleId: 1,
              newStart: DateTime(2024, 6, 15, 10, 0),
              mode: ProgramShiftMode.parallel,
            ),
            false,
          );
        });
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
