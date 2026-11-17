import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../pages/view_gallery_page.dart';
import '../../utility/gallery_viewer.dart';
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
    this.onTap,
  });

  /// Card banner height on View Ministries.
  static const double cardHeight = 220;

  /// Cover height on the ministry detail page.
  static const double detailHeight = 280;

  final String? imageUrl;
  final double height;
  final double borderRadius;

  /// Shared with the tag detail header so the graphic can fly on open and close.
  final String? heroTag;

  /// When set, the graphic opens like a tappable post-head photo.
  final VoidCallback? onTap;

  /// Hero tag shared by the list card, detail cover, and photo viewer.
  static String coverHeroTag(String tagId) => 'user_tag_cover_$tagId';

  /// Opens the cover in the same full-screen viewer used for post head images.
  static void openCoverViewer(
    BuildContext context, {
    required String tagId,
    required String tagName,
    required String? imageUrl,
  }) {
    final raw = imageUrl?.trim() ?? '';
    if (raw.isEmpty) return;
    final src = NetworkImageHelper.sanitizeMediaUrl(raw);
    if (src.isEmpty) return;
    final heroTag = coverHeroTag(tagId);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ViewGalleryPage(
          media: [
            GalleryViewer.photoEntry(
              src: src,
              title: tagName,
              heroTag: heroTag,
            ),
          ],
          initialIndex: 0,
          postId: tagId,
          logPostView: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final raw = imageUrl?.trim() ?? '';
    if (raw.isEmpty) return const SizedBox.shrink();

    final image = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedImageWidget(
        imageUrl: NetworkImageHelper.sanitizeMediaUrl(raw),
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        heroTag: heroTag,
      ),
    );

    if (onTap == null) return image;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap!();
      },
      behavior: HitTestBehavior.opaque,
      child: image,
    );
  }
}
