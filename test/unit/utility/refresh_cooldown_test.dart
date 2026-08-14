import 'package:flutter_test/flutter_test.dart';

import 'package:ctrim_app/utility/refresh_cooldown.dart';

void main() {
  group('hasRefreshCooldownElapsed', () {
    final now = DateTime(2026, 8, 14, 12, 0);

    test('allows refresh when never refreshed', () {
      expect(
        hasRefreshCooldownElapsed(now: now, lastRefreshMs: null),
        isTrue,
      );
    });

    test('blocks refresh inside the cooldown window', () {
      final last = now.subtract(const Duration(minutes: 1, seconds: 59));
      expect(
        hasRefreshCooldownElapsed(now: now, lastRefreshMs: last.millisecondsSinceEpoch),
        isFalse,
      );
    });

    test('allows refresh once the cooldown has elapsed', () {
      final last = now.subtract(kRefreshCooldown);
      expect(
        hasRefreshCooldownElapsed(now: now, lastRefreshMs: last.millisecondsSinceEpoch),
        isTrue,
      );
    });
  });
}
