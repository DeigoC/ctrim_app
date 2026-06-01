import 'package:flutter_test/flutter_test.dart';

import 'package:ctrim_app/models/event/event_log.dart';

void main() {
  group('EventLog', () {
    group('constructor', () {
      test('creates with an initial log entry', () {
        final firstLog = {'uid': 'user-1', 'log': 'Created post', 'ts': DateTime(2024, 1, 1)};
        final eventLog = EventLog(firstLog);

        expect(eventLog.logs.length, 1);
        expect(eventLog.logs.first['uid'], 'user-1');
        expect(eventLog.logs.first['log'], 'Created post');
      });
    });

    group('addLog', () {
      test('prepends a new log entry', () {
        final firstLog = {'uid': 'user-1', 'log': 'Created', 'ts': DateTime(2024, 1, 1)};
        final eventLog = EventLog(firstLog);

        final secondTs = DateTime(2024, 1, 2);
        eventLog.addLog(log: 'Updated', uid: 'user-2', ts: secondTs);

        expect(eventLog.logs.length, 2);
        // addLog inserts at index 0, so newest is first
        expect(eventLog.logs.first['uid'], 'user-2');
        expect(eventLog.logs.first['log'], 'Updated');
        expect(eventLog.logs.first['ts'], secondTs);
      });
    });

    group('orderLogsBackwards', () {
      test('sorts logs in descending timestamp order', () {
        final eventLog = EventLog({'uid': 'user-1', 'log': 'First', 'ts': DateTime(2024, 1, 1)});
        eventLog.addLog(log: 'Second', uid: 'user-2', ts: DateTime(2024, 3, 1));
        eventLog.addLog(log: 'Third', uid: 'user-3', ts: DateTime(2024, 2, 1));

        eventLog.orderLogsBackwards();

        expect(eventLog.logs[0]['ts'], DateTime(2024, 3, 1));
        expect(eventLog.logs[1]['ts'], DateTime(2024, 2, 1));
        expect(eventLog.logs[2]['ts'], DateTime(2024, 1, 1));
      });
    });

    group('logs getter', () {
      test('returns an unmodifiable view', () {
        final eventLog = EventLog({'uid': 'user-1', 'log': 'entry', 'ts': DateTime(2024, 1, 1)});
        expect(() => eventLog.logs.add({}), throwsUnsupportedError);
      });
    });
  });
}
