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
      };
    }

    group('fromMap', () {
      test('parses typed local maps', () {
        final template = PostTemplate.fromMap(
          true,
          'tpl1',
          baseLocalMap(
            headMedia: [
              {'title': 'Cover', 'src': 'cover.jpg', 'type': 'img', 'thumbnailSrc': null},
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
    });

    group('toJson', () {
      test('round-trips local serialization', () {
        final original = PostTemplate.fromMap(
          true,
          'roundtrip',
          baseLocalMap(
            headMedia: [
              {'title': 'Cover', 'src': 'cover.jpg', 'type': 'img', 'thumbnailSrc': null},
            ],
          ),
        );

        final json = original.toJson(true);
        json['id'] = original.id;
        final restored = PostTemplate.fromMap(true, json['id'] as String, Map<String, dynamic>.from(json));

        expect(restored.title, original.title);
        expect(restored.headMedia.single['src'], 'cover.jpg');
        expect(restored.startTime, original.startTime);
      });
    });
  });
}
