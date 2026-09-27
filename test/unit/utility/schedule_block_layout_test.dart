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
          for (final hasSubtitle in [true, false]) {
            final fit = ScheduleBlockLayout.forHeight(
              height,
              hasUsers: hasUsers,
              hasSubtitle: hasSubtitle,
            );
            expect(
              fit.requiredHeight,
              lessThanOrEqualTo(height),
              reason: 'height $height (hasUsers: $hasUsers, '
                  'hasSubtitle: $hasSubtitle) overflows by '
                  '${fit.requiredHeight - height}px',
            );
            if (!hasSubtitle) {
              expect(fit.showSubtitle, isFalse);
            }
          }
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

    test('a subtitle waits until a stacked block has a spare line', () {
      final justTitleAndTime = ScheduleBlockLayout.forHeight(
        ScheduleBlockLayout.stackedHeight,
        hasUsers: true,
        hasSubtitle: true,
      );
      expect(justTitleAndTime.showSubtitle, isFalse);
      expect(justTitleAndTime.twoLineTitle, isFalse);

      final withSubtitle = ScheduleBlockLayout.forHeight(
        ScheduleBlockLayout.subtitleHeight,
        hasUsers: true,
        hasSubtitle: true,
      );
      expect(withSubtitle.showSubtitle, isTrue);
      expect(withSubtitle.twoLineTitle, isFalse);

      final justBelow = ScheduleBlockLayout.forHeight(
        ScheduleBlockLayout.subtitleHeight - 0.5,
        hasUsers: true,
        hasSubtitle: true,
      );
      expect(justBelow.showSubtitle, isFalse);
    });

    test('a second title line waits until the subtitle already fits', () {
      final subtitleOnly = ScheduleBlockLayout.forHeight(
        ScheduleBlockLayout.twoLineWithSubtitleHeight - 0.5,
        hasUsers: false,
        hasSubtitle: true,
      );
      expect(subtitleOnly.showSubtitle, isTrue);
      expect(subtitleOnly.twoLineTitle, isFalse);

      final both = ScheduleBlockLayout.forHeight(
        ScheduleBlockLayout.twoLineWithSubtitleHeight,
        hasUsers: false,
        hasSubtitle: true,
      );
      expect(both.showSubtitle, isTrue);
      expect(both.twoLineTitle, isTrue);
    });

    test('a tall block with no detail never reserves a subtitle line', () {
      final fit = ScheduleBlockLayout.forHeight(
        ScheduleBlockLayout.twoLineWithSubtitleHeight,
        hasUsers: true,
      );

      expect(fit.showSubtitle, isFalse);
      expect(fit.twoLineTitle, isTrue);
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

      seenTwoLine = false;
      var seenSubtitle = false;
      for (var height = ScheduleBlockLayout.compactHeight;
          height <= 400;
          height += 0.5) {
        final fit = ScheduleBlockLayout.forHeight(
          height,
          hasUsers: true,
          hasSubtitle: true,
        );
        if (fit.showSubtitle) seenSubtitle = true;
        if (fit.twoLineTitle) seenTwoLine = true;

        expect(seenSubtitle && !fit.showSubtitle, isFalse,
            reason: 'block at $height dropped its subtitle');
        expect(seenTwoLine && !fit.twoLineTitle, isFalse,
            reason: 'block at $height dropped back to a one-line title');
      }
      expect(seenSubtitle, isTrue);

      expect(seenStacked, isTrue);
      expect(seenTwoLine, isTrue);
    });

    test('avatar stack grows with people when the lane is wide', () {
      const size = ScheduleBlockLayout.bottomAvatar;
      final forTwo = ScheduleBlockLayout.avatarStackWidth(
        userCount: 2,
        avatarSize: size,
        maxWidth: 300,
      );
      final forSix = ScheduleBlockLayout.avatarStackWidth(
        userCount: 6,
        avatarSize: size,
        maxWidth: 300,
      );

      expect(forSix, greaterThan(forTwo));
      // Six faces at 30% max overlap need more than the old hard-coded 68px.
      expect(forSix, greaterThan(68));
      expect(forSix, lessThanOrEqualTo(300));
    });

    test('avatar stack width respects the available max', () {
      expect(
        ScheduleBlockLayout.avatarStackWidth(
          userCount: 8,
          avatarSize: ScheduleBlockLayout.bottomAvatar,
          maxWidth: 60,
        ),
        60,
      );
      expect(
        ScheduleBlockLayout.avatarStackWidth(
          userCount: 1,
          avatarSize: ScheduleBlockLayout.bottomAvatar,
          maxWidth: 200,
        ),
        ScheduleBlockLayout.bottomAvatar,
      );
      expect(
        ScheduleBlockLayout.avatarStackWidth(
          userCount: 0,
          avatarSize: ScheduleBlockLayout.bottomAvatar,
          maxWidth: 200,
        ),
        0,
      );
    });
  });
}
