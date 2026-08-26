import 'package:ctrim_app/pages/events/view_event_local_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('cachedPostDataIsCurrent', () {
    const recentDateMs = 1710000000000;
    const appVersion = '1.2.3';

    test('is false when content is empty', () {
      expect(
        cachedPostDataIsCurrent(
          content: const [],
          recentDateMs: recentDateMs,
          appVersion: appVersion,
        ),
        isFalse,
      );
    });

    test('is false when the header is not timestamp-version', () {
      expect(
        cachedPostDataIsCurrent(
          content: const ['not-a-valid-header-extra'],
          recentDateMs: recentDateMs,
          appVersion: appVersion,
        ),
        isFalse,
      );
    });

    test('is true when timestamp and version match', () {
      expect(
        cachedPostDataIsCurrent(
          content: ['$recentDateMs-$appVersion', '----BODY_START----'],
          recentDateMs: recentDateMs,
          appVersion: appVersion,
        ),
        isTrue,
      );
    });

    test('is false when timestamp or version differ', () {
      expect(
        cachedPostDataIsCurrent(
          content: ['${recentDateMs + 1}-$appVersion'],
          recentDateMs: recentDateMs,
          appVersion: appVersion,
        ),
        isFalse,
      );
      expect(
        cachedPostDataIsCurrent(
          content: ['$recentDateMs-9.9.9'],
          recentDateMs: recentDateMs,
          appVersion: appVersion,
        ),
        isFalse,
      );
    });
  });
}
