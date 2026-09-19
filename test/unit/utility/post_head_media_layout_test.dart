import 'package:ctrim_app/utility/image_orientation.dart';
import 'package:ctrim_app/utility/post_head_media_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PostHeadMediaLayout.plan', () {
    test('returns empty for no media', () {
      expect(PostHeadMediaLayout.plan(const []), PostHeadMediaPlan.empty);
    });

    test('puts a single portrait on the side', () {
      final plan = PostHeadMediaLayout.plan(const [ImageOrientation.portrait]);
      expect(plan.sideIndices, [0]);
      expect(plan.bottomIndices, isEmpty);
    });

    test('puts a single landscape on the bottom', () {
      final plan = PostHeadMediaLayout.plan(const [ImageOrientation.landscape]);
      expect(plan.sideIndices, isEmpty);
      expect(plan.bottomIndices, [0]);
      expect(plan.isSingleBottomFill, isTrue);
    });

    test('puts a single square on the bottom', () {
      final plan = PostHeadMediaLayout.plan(const [ImageOrientation.square]);
      expect(plan.hasSide, isFalse);
      expect(plan.bottomIndices, [0]);
    });

    test('treats unknown (null) as a bottom banner until probed', () {
      final plan = PostHeadMediaLayout.plan(const [null]);
      expect(plan.hasSide, isFalse);
      expect(plan.bottomIndices, [0]);
    });

    test('stacks two portraits on the side', () {
      final plan = PostHeadMediaLayout.plan(const [
        ImageOrientation.portrait,
        ImageOrientation.portrait,
      ]);
      expect(plan.sideIndices, [0, 1]);
      expect(plan.bottomIndices, isEmpty);
    });

    test('keeps two landscapes in a bottom mosaic', () {
      final plan = PostHeadMediaLayout.plan(const [
        ImageOrientation.landscape,
        ImageOrientation.landscape,
      ]);
      expect(plan.sideIndices, isEmpty);
      expect(plan.bottomIndices, [0, 1]);
      expect(plan.isSingleBottomFill, isFalse);
    });

    test('splits mixed pair: portrait side, landscape bottom', () {
      final plan = PostHeadMediaLayout.plan(const [
        ImageOrientation.portrait,
        ImageOrientation.landscape,
      ]);
      expect(plan.sideIndices, [0]);
      expect(plan.bottomIndices, [1]);
    });

    test('keeps original order when the landscape comes first', () {
      final plan = PostHeadMediaLayout.plan(const [
        ImageOrientation.landscape,
        ImageOrientation.portrait,
      ]);
      expect(plan.sideIndices, [1]);
      expect(plan.bottomIndices, [0]);
    });

    test('uses one hero portrait on the side for three portraits', () {
      final plan = PostHeadMediaLayout.plan(const [
        ImageOrientation.portrait,
        ImageOrientation.portrait,
        ImageOrientation.portrait,
      ]);
      expect(plan.sideIndices, [0]);
      expect(plan.bottomIndices, [1, 2]);
    });

    test('puts two portraits on the side when mixed with landscapes', () {
      final plan = PostHeadMediaLayout.plan(const [
        ImageOrientation.portrait,
        ImageOrientation.landscape,
        ImageOrientation.portrait,
        ImageOrientation.landscape,
      ]);
      expect(plan.sideIndices, [0, 2]);
      expect(plan.bottomIndices, [1, 3]);
    });
  });

  group('PostHeadMediaLayout.orientationForEntry', () {
    test('classifies images from intrinsic size', () {
      expect(
        PostHeadMediaLayout.orientationForEntry(
          entry: const {'type': 'img', 'src': 'a.jpg'},
          intrinsic: const Size(800, 1200),
        ),
        ImageOrientation.portrait,
      );
      expect(
        PostHeadMediaLayout.orientationForEntry(
          entry: const {'type': 'img', 'src': 'b.jpg'},
          intrinsic: const Size(1600, 900),
        ),
        ImageOrientation.landscape,
      );
    });

    test('defaults images without a size to landscape', () {
      expect(
        PostHeadMediaLayout.orientationForEntry(
          entry: const {'type': 'img', 'src': 'a.jpg'},
        ),
        ImageOrientation.landscape,
      );
    });

    test('treats video as landscape even with a tall thumbnail size', () {
      expect(
        PostHeadMediaLayout.orientationForEntry(
          entry: const {'type': 'video', 'src': 'clip.mp4'},
          intrinsic: const Size(800, 1200),
        ),
        ImageOrientation.landscape,
      );
    });
  });

  group('PostHeadMediaLayout sizes', () {
    test('side rail is a clamped fraction of the card width', () {
      final single = PostHeadMediaLayout.sideRailWidth(
        sideCount: 1,
        cardWidth: 360,
      );
      expect(single, closeTo(360 * 0.40, 0.01));
      expect(
        PostHeadMediaLayout.sideRailWidth(sideCount: 1, cardWidth: 200),
        PostHeadMediaLayout.sideMinWidth,
      );
      expect(
        PostHeadMediaLayout.sideRailWidth(sideCount: 1, cardWidth: 800),
        PostHeadMediaLayout.sideMaxWidth,
      );
    });

    test('single landscape bottom height follows aspect within caps', () {
      final plan = PostHeadMediaLayout.plan(const [ImageOrientation.landscape]);
      final height = PostHeadMediaLayout.bottomBandHeight(
        plan: plan,
        orientations: const [ImageOrientation.landscape],
        cardWidth: 360,
        singleIntrinsic: const Size(1600, 900),
      );
      expect(height, inInclusiveRange(148, 220));
      expect(height, closeTo(360 * 900 / 1600, 0.5));
    });

    test('unknown single bottom uses the default banner height', () {
      final plan = PostHeadMediaLayout.plan(const [ImageOrientation.landscape]);
      expect(
        PostHeadMediaLayout.bottomBandHeight(
          plan: plan,
          orientations: const [ImageOrientation.landscape],
          cardWidth: 360,
        ),
        PostHeadMediaLayout.unknownSingleBottomHeight,
      );
    });

    test('portrait-heavy mosaics are taller than landscape mosaics', () {
      final plan = PostHeadMediaLayout.plan(const [
        ImageOrientation.portrait,
        ImageOrientation.portrait,
        ImageOrientation.portrait,
      ]);
      expect(
        PostHeadMediaLayout.bottomBandHeight(
          plan: plan,
          orientations: const [
            ImageOrientation.portrait,
            ImageOrientation.portrait,
            ImageOrientation.portrait,
          ],
          cardWidth: 360,
        ),
        PostHeadMediaLayout.portraitMosaicHeight,
      );
    });
  });
}
