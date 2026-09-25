import 'package:flutter/material.dart';

import '../../models/user_tag.dart';
import '../../utility/catalog/user_tag_helpers.dart';
import 'colored_chip.dart';

class UserTagChip extends StatelessWidget {
  const UserTagChip({
    super.key,
    required this.tag,
    this.dense = false,
    this.selected = false,
    this.onTap,
  });

  final UserTag tag;
  final bool dense;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ColoredChip(
      label: tag.name,
      color: UserTagHelpers.parseColor(tag.color),
      dense: dense,
      selected: selected,
      onTap: onTap,
    );
  }
}

class UserTagChipRow extends StatelessWidget {
  const UserTagChipRow({
    super.key,
    required this.tags,
    this.dense = false,
    this.alignment = WrapAlignment.start,
  });

  final List<UserTag> tags;
  final bool dense;
  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return ColoredChipRow(
      alignment: alignment,
      children: [
        for (final tag in tags) UserTagChip(tag: tag, dense: dense),
      ],
    );
  }
}

/// One row of dense team-tag chips. Tags that do not fit are summarized as
/// `+N` so a fixed-height person card never wraps or overflows.
class UserTagChipLine extends StatelessWidget {
  const UserTagChipLine({
    super.key,
    required this.tags,
  });

  final List<UserTag> tags;

  static const double _gap = 6;
  static const double _horizontalPadding = 16;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        if (!maxWidth.isFinite) {
          return UserTagChipRow(tags: tags, dense: true);
        }

        final style = _denseStyle(Theme.of(context));
        final direction = Directionality.of(context);
        final scaler = MediaQuery.textScalerOf(context);
        final widths = [
          for (final tag in tags)
            _chipWidth(tag.name, style, direction, scaler),
        ];

        final visible = _layout(
          widths,
          maxWidth,
          style,
          direction,
          scaler,
        );
        if (visible.count == 0) {
          return Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: UserTagChip(tag: tags.first, dense: true),
            ),
          );
        }

        return Row(
          children: [
            for (var i = 0; i < visible.count; i++) ...[
              if (i > 0) const SizedBox(width: _gap),
              UserTagChip(tag: tags[i], dense: true),
            ],
            if (visible.hidden > 0) ...[
              const SizedBox(width: _gap),
              ColoredChip(label: '+${visible.hidden}', dense: true),
            ],
          ],
        );
      },
    );
  }

  static TextStyle _denseStyle(ThemeData theme) {
    return (theme.textTheme.labelSmall ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w600,
      fontSize: 11,
    );
  }

  static double _chipWidth(
    String label,
    TextStyle style,
    TextDirection direction,
    TextScaler scaler,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: direction,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    return painter.width + _horizontalPadding;
  }

  static ({int count, int hidden}) _layout(
    List<double> widths,
    double maxWidth,
    TextStyle style,
    TextDirection direction,
    TextScaler scaler,
  ) {
    final budget = maxWidth > 1 ? maxWidth - 1 : 0.0;
    for (var count = widths.length; count >= 1; count--) {
      final hidden = widths.length - count;
      var used = 0.0;
      for (var i = 0; i < count; i++) {
        if (i > 0) used += _gap;
        used += widths[i];
      }
      if (hidden > 0) {
        used += _gap + _chipWidth('+$hidden', style, direction, scaler);
      }
      if (used <= budget) return (count: count, hidden: hidden);
    }
    if (widths.first <= budget) return (count: 1, hidden: 0);
    return (count: 0, hidden: widths.length);
  }
}
