import 'package:flutter/material.dart';

import '../../utility/network_image_helper.dart';
import '../media/cached_image_widget.dart';

/// Main graphic for a team tag. Draws nothing when [imageUrl] is empty.
class UserTagGraphic extends StatelessWidget {
  const UserTagGraphic({
    super.key,
    required this.imageUrl,
    this.height = 160,
    this.borderRadius = 16,
    this.heroTag,
  });

  final String? imageUrl;
  final double height;
  final double borderRadius;

  /// Shared with the tag detail header so the graphic can fly on open and close.
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final raw = imageUrl?.trim() ?? '';
    if (raw.isEmpty) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedImageWidget(
        imageUrl: NetworkImageHelper.sanitizeMediaUrl(raw),
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        heroTag: heroTag,
      ),
    );
  }
}
