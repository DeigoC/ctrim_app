import 'package:flutter/material.dart';

import '../../models/post_tag.dart';
import '../../utility/catalog/post_tag_helpers.dart';
import 'colored_chip.dart';

class PostTagChip extends StatelessWidget {
  const PostTagChip({
    super.key,
    required this.tag,
    this.dense = false,
    this.selected = false,
    this.onTap,
  });

  final PostTag tag;
  final bool dense;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ColoredChip(
      label: tag.name,
      color: PostTagHelpers.parseColor(tag.color),
      dense: dense,
      selected: selected,
      onTap: onTap,
    );
  }
}

class PostTagChipRow extends StatelessWidget {
  const PostTagChipRow({
    super.key,
    required this.tags,
    this.dense = false,
    this.alignment = WrapAlignment.start,
  });

  final List<PostTag> tags;
  final bool dense;
  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return ColoredChipRow(
      alignment: alignment,
      children: [
        for (final tag in tags) PostTagChip(tag: tag, dense: dense),
      ],
    );
  }
}
