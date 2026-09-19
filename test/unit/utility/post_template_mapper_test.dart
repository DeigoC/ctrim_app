import 'package:flutter_test/flutter_test.dart';

import 'package:ctrim_app/models/post_template.dart';
import 'package:ctrim_app/utility/event_context.dart';
import 'package:ctrim_app/utility/post_template_mapper.dart';

void main() {
  group('PostTemplateMapper', () {
    Map<String, dynamic> baseLocalMap({
      List? roles,
      List? schedulePresets,
    }) {
      return {
        'Title': 'Sunday Service',
        'Description': 'Weekly gathering',
        'HeadTitle': 'Sunday Service',
        'Body': r'[{"insert":"Hello\n"}]',
        'Location': 'Belfast',
        'Topics': <String>['Belfast'],
        'TagIDs': <String>[],
        'ExpectedAttendeeUserIDs': <String>['expected-1'],
        'Contributors': <String>[],
        'LeadSpeakerUID': null,
        'Subtitles': <String>['Welcome'],
        'AllDay': false,
        'Online': false,
        'Address': '123 Main St',
        'MapLink': '',
        'StartTime': DateTime(2026, 1, 4, 10).millisecondsSinceEpoch,
        'FinishTime': DateTime(2026, 1, 4, 12).millisecondsSinceEpoch,
        'Roles': roles ?? <Map<String, dynamic>>[],
        if (schedulePresets != null) 'SchedulePresets': schedulePresets,
        'HeadMedia': <Map<String, dynamic>>[],
        'Media': <Map<String, dynamic>>[],
        'DefaultDayOfWeek': 0,
        'Logs': <Map<String, dynamic>>[],
      };
    }

    Map<String, dynamic> roleJson({
      required String title,
      required String uid,
      required DateTime start,
      int id = 1,
    }) {
      return {
        'uids': <String>[uid],
        'detail': '',
        'title': title,
        'start': start.millisecondsSinceEpoch,
        'end': start.add(const Duration(minutes: 15)).millisecondsSinceEpoch,
        'for_guests': true,
        'id': id,
        'tagIDs': <String>[],
      };
    }

    PostTemplate templateWithPresets() {
      final map = baseLocalMap(schedulePresets: [
        {
          'id': 'team-a',
          'name': 'Team A',
          'startTime': DateTime(2026, 1, 4, 10).millisecondsSinceEpoch,
          'finishTime': DateTime(2026, 1, 4, 12).millisecondsSinceEpoch,
          'roles': [
            roleJson(
                title: 'Host A',
                uid: 'u1',
                start: DateTime(2026, 1, 4, 10),
                id: 11),
          ],
        },
        {
          'id': 'team-b',
          'name': 'Team B',
          'startTime': DateTime(2026, 1, 4, 10, 30).millisecondsSinceEpoch,
          'finishTime': DateTime(2026, 1, 4, 12, 30).millisecondsSinceEpoch,
          'roles': [
            roleJson(
                title: 'Host B',
                uid: 'u2',
                start: DateTime(2026, 1, 4, 10, 30),
                id: 22),
          ],
        },
      ]);
      return PostTemplate.fromMap(true, 'tpl', map);
    }

    test('maps the first preset when none is specified', () {
      final context = PostTemplateMapper.mapTemplateToEventContext(
        template: templateWithPresets(),
        currentUserID: 'author-1',
      );

      expect(context.program.roles.single['title'], 'Host A');
      expect(context.head.eventDate, DateTime(2026, 1, 4, 10));
      expect(context.program.finishTime, DateTime(2026, 1, 4, 12));
      expect(context.expectedAttendeeUserIDs, ['expected-1']);
    });

    test('maps an explicit schedule preset', () {
      final template = templateWithPresets();
      final context = PostTemplateMapper.mapTemplateToEventContext(
        template: template,
        currentUserID: 'author-1',
        schedulePresetId: 'team-b',
      );

      expect(context.program.roles.single['title'], 'Host B');
      expect(context.head.eventDate, DateTime(2026, 1, 4, 10, 30));
      expect(context.program.finishTime, DateTime(2026, 1, 4, 12, 30));
    });

    test('mints new role ids instead of reusing preset ids', () {
      final template = templateWithPresets();
      final context = PostTemplateMapper.mapTemplateToEventContext(
        template: template,
        currentUserID: 'author-1',
        schedulePreset: template.presetById('team-a'),
      );

      expect(context.program.roles.single['id'], isNot(11));
    });

    test('date-shifts start, finish, and role times', () {
      final template = templateWithPresets();
      final context = PostTemplateMapper.mapTemplateToEventContext(
        template: template,
        currentUserID: 'author-1',
        schedulePresetId: 'team-b',
      );
      PostTemplateMapper.adjustEventProgramToDate(
          context, DateTime(2026, 3, 15));

      expect(context.head.eventDate, DateTime(2026, 3, 15, 10, 30));
      expect(context.program.finishTime, DateTime(2026, 3, 15, 12, 30));
      expect(
        context.program.roles.single['start'],
        DateTime(2026, 3, 15, 10, 30),
      );
    });

    test('leaves an empty programme when the template has no presets', () {
      final map = baseLocalMap();
      map['StartTime'] = null;
      map['FinishTime'] = null;
      final template = PostTemplate.fromMap(true, 'empty', map);
      final context = PostTemplateMapper.mapTemplateToEventContext(
        template: template,
        currentUserID: 'author-1',
      );

      expect(context.program.roles, isEmpty);
      expect(context.head.eventDate, isNull);
    });

    test('override tracks role add/remove and does not touch expected people',
        () {
      final context = EventContext.adding(currentUserID: 'author-1');
      context.head.setEventDate(DateTime(2026, 3, 15, 9));
      context.program.addRole(
        uids: ['old-user'],
        title: 'Old host',
        start: DateTime(2026, 3, 15, 9),
        end: DateTime(2026, 3, 15, 9, 15),
        id: 99,
      );
      context.applyExpectedAttendeeUserIDs(['expected-1']);

      PostTemplateMapper.applySchedulePreset(
        context,
        templateWithPresets().presetById('team-b'),
        eventDate: DateTime(2026, 3, 15),
        trackRoleDiff: true,
      );

      expect(context.program.roles.single['title'], 'Host B');
      expect(context.head.eventDate, DateTime(2026, 3, 15, 10, 30));
      expect(context.program.finishTime, DateTime(2026, 3, 15, 12, 30));
      expect(context.expectedAttendeeUserIDs, ['expected-1']);
      expect(context.roleRemovalals[99], ['old-user']);
      expect(context.deletedRoleTitle(99), 'Old host');
      expect(context.roleAdditions.values.single, ['u2']);
      expect(context.program.roles.single['id'], isNot(22));
      expect(context.program.roles.single['id'], isNot(99));
    });

    test('undated override copies clock times without inventing a date', () {
      final context = EventContext.adding(currentUserID: 'author-1');
      context.applyExpectedAttendeeUserIDs(['expected-1']);

      PostTemplateMapper.applySchedulePreset(
        context,
        templateWithPresets().presetById('team-a'),
        applyEventWindow: false,
      );

      expect(context.head.eventDate, isNull);
      expect(context.program.roles.single['title'], 'Host A');
      expect(
        context.program.roles.single['start'],
        DateTime(2026, 1, 4, 10),
      );
      expect(context.program.finishTime, DateTime(2026, 1, 4, 12));
    });
  });
}
