import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ctrim_app/models/user_activity_record.dart';

void main() {
  group('UserActivityRecord', () {
    final ts = DateTime(2026, 8, 14, 12, 30);

    group('constructor', () {
      test('creates with required parameters', () {
        final record = UserActivityRecord(
          log: 'Edited a bulletin post',
          ts: ts,
          documentId: '42',
        );

        expect(record.log, 'Edited a bulletin post');
        expect(record.ts, ts);
        expect(record.documentId, '42');
      });
    });

    group('fromMap', () {
      test('creates from a Firestore-style map', () {
        final record = UserActivityRecord.fromMap({
          'log': 'Created a church record',
          'ts': Timestamp.fromDate(ts),
          'documentId': 'church-1',
        });

        expect(record.log, 'Created a church record');
        expect(record.ts, ts);
        expect(record.documentId, 'church-1');
      });

      test('defaults missing fields', () {
        final record = UserActivityRecord.fromMap({});

        expect(record.log, '');
        expect(record.documentId, '');
        expect(record.ts, DateTime.fromMillisecondsSinceEpoch(0));
      });
    });

    group('toJson', () {
      test('serialises to Firestore-compatible keys', () {
        final record = UserActivityRecord(
          log: 'Updated profile photo',
          ts: ts,
          documentId: '7',
        );

        final json = record.toJson();

        expect(json['log'], 'Updated profile photo');
        expect(json['documentId'], '7');
        expect(json['ts'], isA<Timestamp>());
        expect((json['ts'] as Timestamp).toDate(), ts);
      });
    });
  });
}
