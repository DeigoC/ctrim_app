import 'package:flutter/material.dart';

/// Two-column paired rows so left-to-right, top-to-bottom stays chronological.
///
/// Use when [ResponsiveLayout.isWideScreenOf] is true. On phones, keep a
/// single-column [ListView] / [SliverList] instead.
class PairedRowList extends StatelessWidget {
  const PairedRowList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.spacing = 16,
    this.runSpacing = 16,
    this.padding,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double spacing;
  final double runSpacing;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < itemCount; i += 2) {
      if (i > 0) rows.add(SizedBox(height: runSpacing));
      final hasRight = i + 1 < itemCount;
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: itemBuilder(context, i)),
          SizedBox(width: spacing),
          Expanded(
            child: hasRight
                ? itemBuilder(context, i + 1)
                : const SizedBox.shrink(),
          ),
        ],
      ));
    }

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );

    if (padding != null) {
      return Padding(padding: padding!, child: column);
    }
    return column;
  }
}
