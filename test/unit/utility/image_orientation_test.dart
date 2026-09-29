import 'dart:typed_data';

import 'package:ctrim_app/utility/image_orientation.dart';
import 'package:ctrim_app/widgets/media/cached_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 2×4 red PNG. Tall on purpose so a remembered size is portrait.
final Uint8List _portraitPng = Uint8List.fromList(const <int>[
  137,
  80,
  78,
  71,
  13,
  10,
  26,
  10,
  0,
  0,
  0,
  13,
  73,
  72,
  68,
  82,
  0,
  0,
  0,
  2,
  0,
  0,
  0,
  4,
  8,
  2,
  0,
  0,
  0,
  43,
  141,
  121,
  110,
  0,
  0,
  0,
  16,
  73,
  68,
  65,
  84,
  120,
  156,
  99,
  248,
  207,
  192,
  0,
  68,
  12,
  216,
  40,
  0,
  119,
  164,
  7,
  249,
  222,
  87,
  183,
  226,
  0,
  0,
  0,
  0,
  73,
  69,
  78,
  68,
  174,
  66,
  96,
  130,
]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ImageOrientationHelper.fromSize', () {
    test('classifies tall images as portrait', () {
      expect(ImageOrientationHelper.fromSize(800, 1200),
          ImageOrientation.portrait);
      expect(ImageOrientationHelper.fromPixelSize(3, 4),
          ImageOrientation.portrait);
    });

    test('classifies wide images as landscape', () {
      expect(ImageOrientationHelper.fromSize(1600, 900),
          ImageOrientation.landscape);
      expect(ImageOrientationHelper.fromPixelSize(16, 9),
          ImageOrientation.landscape);
    });

    test('classifies near-square images as square', () {
      expect(
          ImageOrientationHelper.fromSize(1000, 1000), ImageOrientation.square);
      expect(
          ImageOrientationHelper.fromSize(1000, 980), ImageOrientation.square);
    });

    test('falls back to landscape for invalid sizes', () {
      expect(
          ImageOrientationHelper.fromSize(0, 100), ImageOrientation.landscape);
      expect(
          ImageOrientationHelper.fromSize(100, 0), ImageOrientation.landscape);
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

  group('ImageOrientationHelper.sizeIfDecoded', () {
    test('returns null until the same bytes have been decoded', () async {
      expect(ImageOrientationHelper.sizeIfDecoded(_portraitPng), isNull);

      final decoded = await ImageOrientationHelper.decodeSize(_portraitPng);
      expect(decoded, const Size(2, 4));
      expect(
          ImageOrientationHelper.sizeIfDecoded(_portraitPng), const Size(2, 4));
    });
  });

  group('CachedImageLoader size memory', () {
    const url = 'https://example.com/hero-portrait.png';

    tearDown(() {
      CachedImageLoader.forgetBytes(url);
    });

    test('sizeFor uses a size remembered before the detail page builds', () {
      expect(CachedImageLoader.sizeFor(url), isNull);

      CachedImageLoader.rememberSize(url, const Size(2, 4));

      expect(CachedImageLoader.peekSize(url), const Size(2, 4));
      expect(CachedImageLoader.sizeFor(url), const Size(2, 4));
      expect(
        ImageOrientationHelper.fromSize(2, 4),
        ImageOrientation.portrait,
      );
    });

    test('forgetBytes drops the remembered size', () {
      CachedImageLoader.rememberSize(url, const Size(2, 4));
      CachedImageLoader.forgetBytes(url);
      expect(CachedImageLoader.peekSize(url), isNull);
    });
  });
}
