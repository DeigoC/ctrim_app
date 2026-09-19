import 'package:flutter/material.dart';

import 'image_orientation.dart';

/// Where bulletin [PostHead] media sits on the card.
///
/// Portraits fill a right-hand rail beside the title; landscapes and squares
/// fill a band along the bottom. Mixed posts split: up to two portraits on the
/// side, the rest in the bottom mosaic.
class PostHeadMediaPlan {
  const PostHeadMediaPlan({
    required this.sideIndices,
    required this.bottomIndices,
  });

  static const empty = PostHeadMediaPlan(
    sideIndices: <int>[],
    bottomIndices: <int>[],
  );

  final List<int> sideIndices;
  final List<int> bottomIndices;

  bool get hasSide => sideIndices.isNotEmpty;
  bool get hasBottom => bottomIndices.isNotEmpty;
  bool get isEmpty => !hasSide && !hasBottom;

  /// One landscape/square (or video) stretched along the bottom edge.
  bool get isSingleBottomFill => !hasSide && bottomIndices.length == 1;

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is PostHeadMediaPlan &&
        _listEquals(sideIndices, other.sideIndices) &&
        _listEquals(bottomIndices, other.bottomIndices);
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(sideIndices),
        Object.hashAll(bottomIndices),
      );

  static bool _listEquals(final List<int> a, final List<int> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}

abstract final class PostHeadMediaLayout {
  static const double mosaicGap = 2;
  static const double sideMinHeight = 192;
  static const double singleBottomMinHeight = 148;
  static const double singleBottomMaxHeight = 220;
  static const double mosaicHeight = 200;
  static const double portraitMosaicHeight = 248;
  static const double sideFraction = 0.40;
  static const double dualSideFraction = 0.34;
  static const double sideMinWidth = 108;
  static const double sideMaxWidth = 176;
  static const double unknownSingleBottomHeight = 180;

  static bool isPortrait(final ImageOrientation? orientation) =>
      orientation == ImageOrientation.portrait;

  /// Videos and unloaded images count as landscape until probed.
  static ImageOrientation orientationForEntry({
    required final Map<String, dynamic> entry,
    final Size? intrinsic,
  }) {
    final type = entry['type'] as String? ?? '';
    if (type != 'img') {
      return ImageOrientation.landscape;
    }
    if (intrinsic == null) {
      return ImageOrientation.landscape;
    }
    return ImageOrientationHelper.fromSize(intrinsic.width, intrinsic.height);
  }

  static PostHeadMediaPlan plan(final List<ImageOrientation?> orientations) {
    if (orientations.isEmpty) {
      return PostHeadMediaPlan.empty;
    }

    final portraitIndices = <int>[];
    final otherIndices = <int>[];
    for (var i = 0; i < orientations.length; i++) {
      if (isPortrait(orientations[i])) {
        portraitIndices.add(i);
      } else {
        otherIndices.add(i);
      }
    }

    final maxSide = _maxSideCount(
      total: orientations.length,
      portraitCount: portraitIndices.length,
    );

    final sideIndices = portraitIndices.take(maxSide).toList(growable: false);
    final bottomIndices = <int>[
      ...portraitIndices.skip(maxSide),
      ...otherIndices,
    ];

    return PostHeadMediaPlan(
      sideIndices: sideIndices,
      bottomIndices: List<int>.unmodifiable(bottomIndices),
    );
  }

  static int _maxSideCount({
    required final int total,
    required final int portraitCount,
  }) {
    if (portraitCount == 0) {
      return 0;
    }
    final allPortrait = portraitCount == total;
    if (allPortrait) {
      return total <= 2 ? total : 1;
    }
    return portraitCount < 2 ? portraitCount : 2;
  }

  static double sideRailWidth({
    required final int sideCount,
    required final double cardWidth,
  }) {
    if (sideCount <= 0 || cardWidth <= 0) {
      return 0;
    }
    final fraction = sideCount >= 2 ? dualSideFraction : sideFraction;
    return (cardWidth * fraction).clamp(sideMinWidth, sideMaxWidth);
  }

  static double bottomBandHeight({
    required final PostHeadMediaPlan plan,
    required final List<ImageOrientation?> orientations,
    required final double cardWidth,
    final Size? singleIntrinsic,
  }) {
    if (!plan.hasBottom) {
      return 0;
    }

    if (plan.isSingleBottomFill) {
      if (singleIntrinsic != null) {
        final fitted = ImageOrientationHelper.fitWithin(
          intrinsic: singleIntrinsic,
          maxWidth: cardWidth,
          maxHeight: singleBottomMaxHeight,
        );
        return fitted.height.clamp(
          singleBottomMinHeight,
          singleBottomMaxHeight,
        );
      }
      return unknownSingleBottomHeight;
    }

    final bottomIsPortraitHeavy =
        plan.bottomIndices.every((i) => isPortrait(orientations[i]));
    return bottomIsPortraitHeavy ? portraitMosaicHeight : mosaicHeight;
  }
}
