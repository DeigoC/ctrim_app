import 'package:ctrim_app/utility/church_social_button_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChurchSocialButtonLayout.columns', () {
    test('one link is a single full-width button', () {
      expect(
        ChurchSocialButtonLayout.columns(count: 1, maxWidth: 400),
        1,
      );
      expect(
        ChurchSocialButtonLayout.columns(count: 0, maxWidth: 400),
        1,
      );
    });

    test('two links share one row when they fit', () {
      expect(
        ChurchSocialButtonLayout.columns(count: 2, maxWidth: 320),
        2,
      );
    });

    test('two links stack when the card is too narrow to share', () {
      expect(
        ChurchSocialButtonLayout.columns(count: 2, maxWidth: 200),
        1,
      );
    });

    test('four links use pairs so the last row is not a single button', () {
      // Three columns fit (148 * 3 + 16 = 460), but 4 % 3 leaves one.
      expect(
        ChurchSocialButtonLayout.columns(count: 4, maxWidth: 480),
        2,
      );
    });

    test('five links use three columns when the card is wide enough', () {
      expect(
        ChurchSocialButtonLayout.columns(count: 5, maxWidth: 480),
        3,
      );
    });

    test('many links wrap at two columns on a typical hub card', () {
      expect(
        ChurchSocialButtonLayout.columns(count: 6, maxWidth: 360),
        2,
      );
    });

    test('a wide card never exceeds three columns', () {
      expect(
        ChurchSocialButtonLayout.columns(count: 9, maxWidth: 1200),
        3,
      );
    });

    test('unknown width stacks buttons', () {
      expect(
        ChurchSocialButtonLayout.columns(count: 4, maxWidth: 0),
        1,
      );
    });
  });
}
