import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Two-column masonry: each child is placed in the currently shorter column.
///
/// Use on wide dashboards where cards have uneven heights. [PairedRowList]
/// keeps reading-order rows (next row waits for both cards); this fills the
/// gap under the shorter card instead.
class TwoColumnMasonry extends MultiChildRenderObjectWidget {
  const TwoColumnMasonry({
    super.key,
    super.children,
    this.spacing = 16,
    this.runSpacing = 16,
  });

  /// Gap between the two columns.
  final double spacing;

  /// Vertical gap between cards in the same column.
  final double runSpacing;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderTwoColumnMasonry(
      spacing: spacing,
      runSpacing: runSpacing,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderTwoColumnMasonry renderObject,
  ) {
    renderObject
      ..spacing = spacing
      ..runSpacing = runSpacing;
  }
}

class _TwoColumnMasonryParentData extends ContainerBoxParentData<RenderBox> {}

class RenderTwoColumnMasonry extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _TwoColumnMasonryParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox,
            _TwoColumnMasonryParentData> {
  RenderTwoColumnMasonry({
    required double spacing,
    required double runSpacing,
  })  : _spacing = spacing,
        _runSpacing = runSpacing;

  double _spacing;
  double get spacing => _spacing;
  set spacing(double value) {
    if (_spacing == value) return;
    _spacing = value;
    markNeedsLayout();
  }

  double _runSpacing;
  double get runSpacing => _runSpacing;
  set runSpacing(double value) {
    if (_runSpacing == value) return;
    _runSpacing = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _TwoColumnMasonryParentData) {
      child.parentData = _TwoColumnMasonryParentData();
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) => 0;

  @override
  double computeMaxIntrinsicWidth(double height) {
    var maxChild = 0.0;
    var child = firstChild;
    while (child != null) {
      maxChild = math.max(maxChild, child.getMaxIntrinsicWidth(height));
      child = childAfter(child);
    }
    return maxChild * 2 + spacing;
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      _computeHeightForWidth(width);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _computeHeightForWidth(width);

  double _computeHeightForWidth(double width) {
    if (childCount == 0) return 0;
    return _layoutChildren(
      BoxConstraints(maxWidth: width.isFinite ? width : 0),
      dry: true,
    );
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    if (childCount == 0) return constraints.smallest;
    final height = _layoutChildren(constraints, dry: true);
    return constraints.constrain(Size(constraints.maxWidth, height));
  }

  @override
  void performLayout() {
    if (childCount == 0) {
      size = constraints.smallest;
      return;
    }
    final height = _layoutChildren(constraints, dry: false);
    size = constraints.constrain(Size(constraints.maxWidth, height));
  }

  double _layoutChildren(BoxConstraints constraints, {required bool dry}) {
    final maxWidth = constraints.maxWidth;
    if (childCount == 1) {
      final child = firstChild!;
      final childConstraints = BoxConstraints(
        minWidth: maxWidth.isFinite ? maxWidth : 0,
        maxWidth: maxWidth.isFinite ? maxWidth : double.infinity,
      );
      final Size childSize;
      if (dry) {
        childSize = child.getDryLayout(childConstraints);
      } else {
        child.layout(childConstraints, parentUsesSize: true);
        childSize = child.size;
        (child.parentData! as _TwoColumnMasonryParentData).offset = Offset.zero;
      }
      return childSize.height;
    }

    final columnWidth =
        maxWidth.isFinite ? math.max(0.0, (maxWidth - spacing) / 2) : 0.0;
    final childConstraints = BoxConstraints(
      minWidth: columnWidth,
      maxWidth: columnWidth,
    );

    var leftY = 0.0;
    var rightY = 0.0;
    var child = firstChild;
    while (child != null) {
      final Size childSize;
      if (dry) {
        childSize = child.getDryLayout(childConstraints);
      } else {
        child.layout(childConstraints, parentUsesSize: true);
        childSize = child.size;
      }

      final placeLeft = leftY <= rightY;
      if (!dry) {
        final parentData = child.parentData! as _TwoColumnMasonryParentData;
        parentData.offset = Offset(
          placeLeft ? 0 : columnWidth + spacing,
          placeLeft ? leftY : rightY,
        );
      }
      if (placeLeft) {
        leftY += childSize.height + runSpacing;
      } else {
        rightY += childSize.height + runSpacing;
      }
      child = childAfter(child);
    }

    final raw = math.max(leftY, rightY);
    return raw > 0 ? raw - runSpacing : 0;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }
}
