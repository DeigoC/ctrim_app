import 'package:flutter/material.dart';

import '../utility/responsive_layout.dart';

/// Centers page content and applies wide-screen gutters and optional max-width.
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
        final horizontal = ResponsiveLayout.horizontalGutter(
          width,
          style: gutter,
          narrowPadding: narrowPadding,
        );
        final contentMaxWidth = maxContentWidthOverride ??
            (maxWidth ? ResponsiveLayout.maxContentWidth(width) : width);

        return Align(
          alignment: alignment,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentMaxWidth),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontal),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
