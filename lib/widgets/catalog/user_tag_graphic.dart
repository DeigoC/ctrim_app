import 'package:flutter/material.dart';

import '../../utility/network_image_helper.dart';

/// Main graphic for a team tag. Draws nothing when [imageUrl] is empty.
class UserTagGraphic extends StatelessWidget {
  const UserTagGraphic({
    super.key,
    required this.imageUrl,
    this.height = 160,
    this.borderRadius = 16,
  });

  final String? imageUrl;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final raw = imageUrl?.trim() ?? '';
    if (raw.isEmpty) return const SizedBox.shrink();

    final url = NetworkImageHelper.getImageUrl(
      NetworkImageHelper.sanitizeMediaUrl(raw),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.network(
        url,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }
}
