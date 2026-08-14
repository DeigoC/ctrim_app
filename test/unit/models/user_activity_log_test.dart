import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ctrim_app/models/user_activity_log.dart';
import 'package:ctrim_app/models/user_activity_record.dart';

void main() {
  group('UserActivityLog', () {
    group('constructor', () {
      test('starts empty', () {
        final log = UserActivityLog();
        expect(log.records, isEmpty);
        expect(log.preview, isEmpty);
      });

      test('copies the given records', () {
        final first = UserActivityRecord(
          log: 'A',
          ts: DateTime(2026, 1, 1),
          documentId: '1',
        );
        final log = UserActivityLog([first]);
        expect(log.records.length, 1);
        expect(log.records.first.log, 'A');
      });
    });

    group('fromMap', () {
      test('parses Logs newest-first', () {
        final log = UserActivityLog.fromMap({
          'Logs': [
            {
              'log': 'Newest',
              'ts': Timestamp.fromDate(DateTime(2026, 2, 1)),
              'documentId': '2',
            },
            {
              'log': 'Older',
              'ts': Timestamp.fromDate(DateTime(2026, 1, 1)),
              'documentId': '1',
            },
          ],
        });

        expect(log.records.length, 2);
        expect(log.records.first.log, 'Newest');
        expect(log.records.last.documentId, '1');
      });

      test('treats missing Logs as empty', () {
        final log = UserActivityLog.fromMap({});
        expect(log.records, isEmpty);
      });
    });

    group('toJson', () {
      test('round-trips through fromMap', () {
        final original = UserActivityLog([
          UserActivityRecord(
            log: 'Edited a bulletin post',
            ts: DateTime(2026, 8, 14, 10),
            documentId: '99',
          ),
        ]);

        final restored = UserActivityLog.fromMap(original.toJson());
        expect(restored.records.length, 1);
        expect(restored.records.first.log, 'Edited a bulletin post');
        expect(restored.records.first.documentId, '99');
        expect(restored.records.first.ts, DateTime(2026, 8, 14, 10));
      });
    });

    group('add', () {
      test('prepends a new entry', () {
        final log = UserActivityLog();
        log.add(log: 'First', documentId: '1', ts: DateTime(2026, 1, 1));
        log.add(log: 'Second', documentId: '2', ts: DateTime(2026, 1, 2));

        expect(log.records.length, 2);
        expect(log.records.first.log, 'Second');
        expect(log.records.last.log, 'First');
      });

      test('caps at maxStoredRecords', () {
        final log = UserActivityLog();
        for (var i = 0; i < UserActivityLog.maxStoredRecords + 5; i++) {
          log.add(log: 'Entry $i', documentId: '$i', ts: DateTime(2026, 1, 1));
        }

        expect(log.records.length, UserActivityLog.maxStoredRecords);
        expect(log.records.first.log,
            'Entry ${UserActivityLog.maxStoredRecords + 4}');
        expect(log.records.last.log, 'Entry 5');
      });
    });

    group('preview', () {
      test('returns at most publicPreviewCount entries', () {
        final log = UserActivityLog();
        for (var i = 0; i < 8; i++) {
          log.add(log: 'E$i', documentId: '$i', ts: DateTime(2026, 1, 1));
        }

        expect(log.preview.length, UserActivityLog.publicPreviewCount);
        expect(log.preview.first.log, 'E7');
      });
    });

    group('records getter', () {
      test('returns an unmodifiable view', () {
        final log = UserActivityLog();
        log.add(log: 'A', documentId: '1', ts: DateTime(2026, 1, 1));
        expect(
          () => log.records.add(
            UserActivityRecord(
                log: 'x', ts: DateTime(2026, 1, 1), documentId: 'x'),
          ),
          throwsUnsupportedError,
        );
      });
    });
  });
}
