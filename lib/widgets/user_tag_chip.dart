import 'package:flutter/material.dart';

import '../models/user_tag.dart';
import '../utility/user_tag_helpers.dart';
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
