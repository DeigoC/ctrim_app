import 'package:flutter/material.dart';

import '../utility/responsive_layout.dart';

/// Centers page content and applies wide-screen gutters and optional max-width.
///
/// When a max width is in effect, side space is the leftover
/// `(parentWidth - maxWidth) / 2` — not a percentage inset inside the capped box
/// (which would make settings pages look overly narrow).
class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({
    super.key,
    required this.child,
    this.gutter = GutterStyle.standard,
    this.narrowPadding = 0,
    this.maxWidth = true,
    this.maxContentWidthOverride,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final GutterStyle gutter;
  final double narrowPadding;
  final bool maxWidth;
  final double? maxContentWidthOverride;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final useMaxWidth = maxContentWidthOverride != null || maxWidth;
        final contentMaxWidth = maxContentWidthOverride ??
            (maxWidth ? ResponsiveLayout.maxContentWidth(width) : width);

        final double horizontal;
        if (useMaxWidth) {
          horizontal = width > contentMaxWidth
              ? (width - contentMaxWidth) / 2
              : narrowPadding;
        } else {
          horizontal = ResponsiveLayout.horizontalGutter(
            width,
            style: gutter,
            narrowPadding: narrowPadding,
          );
        }

        return Align(
          alignment: alignment,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontal),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentMaxWidth),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
