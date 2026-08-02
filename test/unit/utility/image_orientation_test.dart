import 'package:ctrim_app/utility/image_orientation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ImageOrientationHelper.fromSize', () {
    test('classifies tall images as portrait', () {
      expect(ImageOrientationHelper.fromSize(800, 1200), ImageOrientation.portrait);
      expect(ImageOrientationHelper.fromPixelSize(3, 4), ImageOrientation.portrait);
    });

    test('classifies wide images as landscape', () {
      expect(ImageOrientationHelper.fromSize(1600, 900), ImageOrientation.landscape);
      expect(ImageOrientationHelper.fromPixelSize(16, 9), ImageOrientation.landscape);
    });

    test('classifies near-square images as square', () {
      expect(ImageOrientationHelper.fromSize(1000, 1000), ImageOrientation.square);
      expect(ImageOrientationHelper.fromSize(1000, 980), ImageOrientation.square);
    });

    test('falls back to landscape for invalid sizes', () {
      expect(ImageOrientationHelper.fromSize(0, 100), ImageOrientation.landscape);
      expect(ImageOrientationHelper.fromSize(100, 0), ImageOrientation.landscape);
    });
  });

  group('ImageOrientationHelper.fitWithin', () {
    test('keeps portrait images tall and narrow inside bounds', () {
      final fitted = ImageOrientationHelper.fitWithin(
        intrinsic: const Size(800, 1200),
        maxWidth: 420,
        maxHeight: 600,
      );

      expect(fitted.width, lessThanOrEqualTo(420));
      expect(fitted.height, lessThanOrEqualTo(600));
      expect(fitted.width / fitted.height, closeTo(800 / 1200, 0.001));
      expect(fitted.height, greaterThan(fitted.width));
    });

    test('keeps landscape images wide inside bounds', () {
      final fitted = ImageOrientationHelper.fitWithin(
        intrinsic: const Size(1600, 900),
        maxWidth: 1000,
        maxHeight: 400,
      );

      expect(fitted.width, lessThanOrEqualTo(1000));
      expect(fitted.height, lessThanOrEqualTo(400));
      expect(fitted.width / fitted.height, closeTo(1600 / 900, 0.001));
      expect(fitted.width, greaterThan(fitted.height));
    });
  });
}
