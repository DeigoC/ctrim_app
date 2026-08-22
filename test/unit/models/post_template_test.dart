import 'package:flutter_test/flutter_test.dart';

import 'package:ctrim_app/models/post_template.dart';

void main() {
  group('PostTemplate', () {
    Map<String, dynamic> baseLocalMap({
      List? roles,
      List? headMedia,
      List? media,
      List? headMediaPool,
      List? bodyMediaPool,
    }) {
      return {
        'Title': 'Sunday Service',
        'Description': 'Weekly gathering',
        'HeadTitle': 'Sunday Service',
        'Body': r'[{"insert":"Hello\n"}]',
        'Location': 'Belfast',
        'Topics': <String>['Belfast'],
        'TagIDs': <String>[],
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
        'HeadMedia': headMedia ?? <Map<String, dynamic>>[],
        'Media': media ?? <Map<String, dynamic>>[],
        'HeadMediaPool': headMediaPool,
        'BodyMediaPool': bodyMediaPool,
        'DefaultDayOfWeek': 0,
        'Logs': <Map<String, dynamic>>[],
      };
    }

    group('fromMap', () {
      test('parses typed local maps', () {
        final template = PostTemplate.fromMap(
          true,
          'tpl1',
          baseLocalMap(
            headMedia: [
              {
                'title': 'Cover',
                'src': 'cover.jpg',
                'type': 'img',
                'thumbnailSrc': null
              },
            ],
            roles: [
              {
                'uids': <String>['u1'],
                'detail': 'Welcome',
                'title': 'Host',
                'start': DateTime(2026, 1, 4, 10).millisecondsSinceEpoch,
                'end': DateTime(2026, 1, 4, 10, 15).millisecondsSinceEpoch,
                'for_guests': true,
                'id': 1,
              },
            ],
          ),
        );

        expect(template.id, 'tpl1');
        expect(template.title, 'Sunday Service');
        expect(template.headMedia.single['src'], 'cover.jpg');
        expect(template.roles.single['title'], 'Host');
        expect(template.roles.single['start'], isA<DateTime>());
        expect(template.leadSpeakerUID, isNull);
      });

      test('parses LeadSpeakerUID when present', () {
        final map = baseLocalMap();
        map['LeadSpeakerUID'] = 'speaker-1';
        final template = PostTemplate.fromMap(true, 'tpl-speaker', map);

        expect(template.leadSpeakerUID, 'speaker-1');
      });

      test('defaults IsPeriodParent to false and reads true', () {
        final plain = PostTemplate.fromMap(true, 'tpl-plain', baseLocalMap());
        expect(plain.isPeriodParent, false);

        final map = baseLocalMap();
        map['IsPeriodParent'] = true;
        final period = PostTemplate.fromMap(true, 'tpl-period', map);
        expect(period.isPeriodParent, true);
        expect(period.toJson(true)['IsPeriodParent'], true);
      });

      test('defaults Category to service when missing', () {
        final template =
            PostTemplate.fromMap(true, 'tpl-plain', baseLocalMap());
        expect(template.category, PostTemplateCategory.service);
        expect(template.toJson(true)['Category'], 'service');
      });

      test('parses Category cellGroup', () {
        final map = baseLocalMap();
        map['Category'] = 'cellGroup';
        final template = PostTemplate.fromMap(true, 'tpl-cg-cat', map);
        expect(template.category, PostTemplateCategory.cellGroup);
        expect(template.toJson(true)['Category'], 'cellGroup');
      });

      test('defaults CellGroupIDs to empty and reads list', () {
        final plain = PostTemplate.fromMap(true, 'tpl-plain', baseLocalMap());
        expect(plain.cellGroupIDs, isEmpty);

        final map = baseLocalMap();
        map['CellGroupIDs'] = <String>['cg1', 'cg2'];
        final linked = PostTemplate.fromMap(true, 'tpl-cg', map);
        expect(linked.cellGroupIDs, ['cg1', 'cg2']);
        expect(linked.toJson(true)['CellGroupIDs'], ['cg1', 'cg2']);
      });

      test('defaults ExpectedAttendeeUserIDs to empty and reads list', () {
        final plain = PostTemplate.fromMap(true, 'tpl-plain', baseLocalMap());
        expect(plain.expectedAttendeeUserIDs, isEmpty);

        final map = baseLocalMap();
        map['ExpectedAttendeeUserIDs'] = <String>['u1', 'u2'];
        final withExpected = PostTemplate.fromMap(true, 'tpl-exp', map);
        expect(withExpected.expectedAttendeeUserIDs, ['u1', 'u2']);
        expect(
            withExpected.toJson(true)['ExpectedAttendeeUserIDs'], ['u1', 'u2']);
      });

      test('accepts Hive-style Map<dynamic, dynamic> nested entries', () {
        // Mirrors what Hive returns from box.get — LinkedMap<dynamic, dynamic>
        final hiveHeadMedia = <dynamic>[
          Map<dynamic, dynamic>.from({
            'title': 'Cover',
            'src': 'cover.jpg',
            'type': 'img',
            'thumbnailSrc': null,
          }),
        ];
        final hiveRoles = <dynamic>[
          Map<dynamic, dynamic>.from({
            'uids': <dynamic>['u1'],
            'detail': 'Welcome',
            'title': 'Host',
            'start': DateTime(2026, 1, 4, 10).millisecondsSinceEpoch,
            'end': null,
            'for_guests': false,
            'id': 42,
          }),
        ];
        final hivePool = <dynamic>[
          Map<dynamic, dynamic>.from({
            'title': 'Alt',
            'src': 'alt.jpg',
            'type': 'img',
            'thumbnailSrc': null,
          }),
        ];

        final template = PostTemplate.fromMap(
          true,
          'ByDIGlhNrEtE6W0U5CdP',
          baseLocalMap(
            roles: hiveRoles,
            headMedia: hiveHeadMedia,
            media: hiveHeadMedia,
            headMediaPool: hivePool,
            bodyMediaPool: hivePool,
          ),
        );

        expect(template.id, 'ByDIGlhNrEtE6W0U5CdP');
        expect(template.headMedia.single['src'], 'cover.jpg');
        expect(template.media.single['type'], 'img');
        expect(template.headMediaPool.single['src'], 'alt.jpg');
        expect(template.bodyMediaPool.single['src'], 'alt.jpg');
        expect(template.roles.single['uids'], ['u1']);
        expect(template.roles.single['id'], 42);
      });
      test('keyGraphicPool prefers body media pool over head media pool', () {
        final template = PostTemplate.fromMap(
          true,
          'key-pool',
          baseLocalMap(
            headMediaPool: [
              {
                'title': 'Head',
                'src': 'head.jpg',
                'type': 'img',
                'thumbnailSrc': null
              },
            ],
            bodyMediaPool: [
              {
                'title': 'Body',
                'src': 'body.jpg',
                'type': 'img',
                'thumbnailSrc': null
              },
            ],
          ),
        );

        expect(template.keyGraphicPool.single['src'], 'body.jpg');
        expect(template.getRandomKeyGraphicPoolItem()?['src'], 'body.jpg');
      });

      test('keyGraphicPool falls back to head media pool', () {
        final template = PostTemplate.fromMap(
          true,
          'key-pool-fallback',
          baseLocalMap(
            headMediaPool: [
              {
                'title': 'Head',
                'src': 'head.jpg',
                'type': 'img',
                'thumbnailSrc': null
              },
            ],
          ),
        );

        expect(template.keyGraphicPool.single['src'], 'head.jpg');
      });

      test('defaults Logs to empty when missing', () {
        final map = baseLocalMap();
        map.remove('Logs');
        final template = PostTemplate.fromMap(true, 'no-logs', map);

        expect(template.logs, isEmpty);
      });

      test('parses Logs with local epoch timestamps', () {
        final map = baseLocalMap();
        map['Logs'] = [
          {
            'uid': 'user-1',
            'log': 'Created',
            'ts': DateTime(2026, 8, 1, 10).millisecondsSinceEpoch,
          },
        ];
        final template = PostTemplate.fromMap(true, 'with-logs', map);

        expect(template.logs.length, 1);
        expect(template.logs.single['uid'], 'user-1');
        expect(template.logs.single['log'], 'Created');
        expect(template.logs.single['ts'], DateTime(2026, 8, 1, 10));
      });
    });

    group('addLog', () {
      test('prepends a new log entry', () {
        final template = PostTemplate.fromMap(true, 'add-log', baseLocalMap());
        template.addLog(log: 'Created', uid: 'u1', ts: DateTime(2026, 8, 1));
        template.addLog(
            log: 'Updated cover', uid: 'u2', ts: DateTime(2026, 8, 2));

        expect(template.logs.length, 2);
        expect(template.logs.first['log'], 'Updated cover');
        expect(template.logs.first['uid'], 'u2');
        expect(template.logs.last['log'], 'Created');
      });

      test('logs getter is unmodifiable', () {
        final template = PostTemplate.fromMap(true, 'unmod', baseLocalMap());
        expect(() => template.logs.add({}), throwsUnsupportedError);
      });
    });

    group('toJson', () {
      test('round-trips local serialization', () {
        final original = PostTemplate.fromMap(
          true,
          'roundtrip',
          baseLocalMap(
            headMedia: [
              {
                'title': 'Cover',
                'src': 'cover.jpg',
                'type': 'img',
                'thumbnailSrc': null
              },
            ],
          ),
        );
        original.addLog(
            log: 'Created', uid: 'u1', ts: DateTime(2026, 8, 1, 12));

        final json = original.toJson(true);
        json['id'] = original.id;
        final restored = PostTemplate.fromMap(
            true, json['id'] as String, Map<String, dynamic>.from(json));

        expect(restored.title, original.title);
        expect(restored.headMedia.single['src'], 'cover.jpg');
        expect(restored.startTime, original.startTime);
        expect(restored.category, PostTemplateCategory.service);
        expect(restored.logs.single['log'], 'Created');
        expect(restored.logs.single['uid'], 'u1');
        expect(restored.logs.single['ts'], DateTime(2026, 8, 1, 12));
      });
    });

    group('PostTemplateCategory', () {
      test('fromFirestore maps known values and defaults unknowns to service',
          () {
        expect(PostTemplateCategory.fromFirestore('cellGroup'),
            PostTemplateCategory.cellGroup);
        expect(PostTemplateCategory.fromFirestore('CELLGROUP'),
            PostTemplateCategory.cellGroup);
        expect(PostTemplateCategory.fromFirestore('service'),
            PostTemplateCategory.service);
        expect(PostTemplateCategory.fromFirestore(null),
            PostTemplateCategory.service);
        expect(PostTemplateCategory.fromFirestore(''),
            PostTemplateCategory.service);
        expect(PostTemplateCategory.fromFirestore('other'),
            PostTemplateCategory.service);
      });
    });
  });
}
