import 'package:ctrim_app/utility/schedule_block_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScheduleBlockLayout', () {
    test('content never needs more room than the block has', () {
      // The bug this guards: a ten-minute block is 48px, and the stacked
      // layout needed 50px, so it overflowed by exactly 2 pixels.
      for (var height = ScheduleBlockLayout.compactHeight;
          height <= 400;
          height += 0.5) {
        for (final hasUsers in [true, false]) {
          final fit = ScheduleBlockLayout.forHeight(height, hasUsers: hasUsers);
          expect(
            fit.requiredHeight,
            lessThanOrEqualTo(height),
            reason: 'height $height (hasUsers: $hasUsers) overflows by '
                '${fit.requiredHeight - height}px',
          );
        }
      }
    });

    test('a ten-minute block stays on one line', () {
      final fit = ScheduleBlockLayout.forHeight(48, hasUsers: true);

      expect(fit.stacked, isFalse);
      expect(fit.avatars, ScheduleBlockAvatars.inline);
      expect(fit.twoLineTitle, isFalse);
    });

    test('the smallest block still shows its avatars inline', () {
      final fit = ScheduleBlockLayout.forHeight(
        ScheduleBlockLayout.compactHeight,
        hasUsers: true,
      );

      expect(fit.stacked, isFalse);
      expect(fit.avatars, ScheduleBlockAvatars.inline);
    });

    test('a block with no users never reserves avatar space', () {
      for (final height in [24.0, 60.0, 90.0, 200.0]) {
        final fit = ScheduleBlockLayout.forHeight(height, hasUsers: false);
        expect(fit.avatars, ScheduleBlockAvatars.none);
      }
    });

    test('title and time stack once there is room for both', () {
      final fit = ScheduleBlockLayout.forHeight(
        ScheduleBlockLayout.stackedHeight,
        hasUsers: true,
      );

      expect(fit.stacked, isTrue);
      expect(fit.avatars, ScheduleBlockAvatars.inline);
    });

    test('avatars drop to the bottom edge on a tall block', () {
      final fit = ScheduleBlockLayout.forHeight(
        ScheduleBlockLayout.twoLineWithBottomAvatarHeight,
        hasUsers: true,
      );

      expect(fit.avatars, ScheduleBlockAvatars.bottom);
      expect(fit.twoLineTitle, isTrue);
    });

    test('avatars stay inline rather than costing a title line', () {
      // Tall enough for bottom avatars on their own, but not alongside the
      // two-line title this height has already earned.
      final fit = ScheduleBlockLayout.forHeight(
        ScheduleBlockLayout.bottomAvatarHeight,
        hasUsers: true,
      );

      expect(fit.twoLineTitle, isTrue);
      expect(fit.avatars, ScheduleBlockAvatars.inline);
    });

    test('a second title line waits for the space it needs', () {
      final withoutAvatars = ScheduleBlockLayout.forHeight(
        ScheduleBlockLayout.twoLineHeight,
        hasUsers: false,
      );
      expect(withoutAvatars.twoLineTitle, isTrue);

      final justBelow = ScheduleBlockLayout.forHeight(
        ScheduleBlockLayout.twoLineHeight - 0.5,
        hasUsers: false,
      );
      expect(justBelow.twoLineTitle, isFalse);
    });

    test('taller blocks never show less than shorter ones', () {
      var seenStacked = false;
      var seenTwoLine = false;

      for (var height = ScheduleBlockLayout.compactHeight;
          height <= 400;
          height += 0.5) {
        final fit = ScheduleBlockLayout.forHeight(height, hasUsers: true);
        if (fit.stacked) seenStacked = true;
        if (fit.twoLineTitle) seenTwoLine = true;

        expect(seenStacked && !fit.stacked, isFalse,
            reason: 'block at $height dropped back to a single line');
        expect(seenTwoLine && !fit.twoLineTitle, isFalse,
            reason: 'block at $height dropped back to a one-line title');
      }

      expect(seenStacked, isTrue);
      expect(seenTwoLine, isTrue);
    });
  });
}
