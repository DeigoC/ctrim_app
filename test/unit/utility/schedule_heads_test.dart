import 'package:flutter_test/flutter_test.dart';

import 'package:ctrim_app/models/event/event_head.dart';
import 'package:ctrim_app/utility/schedule_heads.dart';

void main() {
  group('ScheduleHeads', () {
    EventHead head(String id, {String title = 'Event'}) =>
        EventHead(id: id, title: title);

    group('missingPostIDs', () {
      test('skips ids already in known heads and empty ids', () {
        expect(
          ScheduleHeads.missingPostIDs(
            postIDs: ['a', 'b', 'a', '', 'c'],
            knownHeads: [head('a')],
          ),
          ['b', 'c'],
        );
      });

      test('returns empty when every id is already known', () {
        expect(
          ScheduleHeads.missingPostIDs(
            postIDs: ['a', 'b'],
            knownHeads: [head('a'), head('b')],
          ),
          isEmpty,
        );
      });
    });

    group('merge', () {
      test('session heads win over extras with the same id', () {
        final session = [head('a', title: 'Bulletin')];
        final extra = {'a': head('a', title: 'Schedule extra'), 'b': head('b')};

        final merged = ScheduleHeads.merge(
          sessionHeads: session,
          extraHeads: extra,
        );

        expect(merged.map((h) => h.id).toSet(), {'a', 'b'});
        expect(
          merged.firstWhere((h) => h.id == 'a').title,
          'Bulletin',
        );
      });

      test('copies session list when extras are empty', () {
        final session = [head('a')];
        final merged = ScheduleHeads.merge(
          sessionHeads: session,
          extraHeads: const {},
        );
        expect(merged, [session.first]);
        expect(identical(merged, session), isFalse);
      });
    });

    group('lookup', () {
      test('prefers session then extra', () {
        final session = [head('a', title: 'Session')];
        final extra = {
          'a': head('a', title: 'Extra'),
          'b': head('b', title: 'Only extra'),
        };

        expect(
          ScheduleHeads.lookup(
            postID: 'a',
            sessionHeads: session,
            extraHeads: extra,
          )?.title,
          'Session',
        );
        expect(
          ScheduleHeads.lookup(
            postID: 'b',
            sessionHeads: session,
            extraHeads: extra,
          )?.title,
          'Only extra',
        );
        expect(
          ScheduleHeads.lookup(
            postID: 'missing',
            sessionHeads: session,
            extraHeads: extra,
          ),
          isNull,
        );
      });
    });
  });
}
