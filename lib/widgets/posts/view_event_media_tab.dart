import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../pages/events/edit_gallery_page.dart';
import '../../pages/view_gallery_page.dart';
import '../../utility/event_context.dart';
import '../../utility/network_image_helper.dart';
import '../media/image_media_slot.dart';
import '../media/video_media_slot.dart';

class ViewEventMediaTab extends StatefulWidget {
  const ViewEventMediaTab({super.key, required this.eventContext, required this.currentUID});
  final EventContext eventContext;
  final String currentUID;

  @override
  State<ViewEventMediaTab> createState() => _ViewEventMediaTabState();
}

class _ViewEventMediaTabState extends State<ViewEventMediaTab> {
  Map<String, dynamic>? _selectedTemplateMedia;

  @override
  void initState() {
    super.initState();
    final bodyMediaPool = widget.eventContext.templateBodyMediaPool;
    if (bodyMediaPool != null && bodyMediaPool.isNotEmpty) {
      final currentMedia = widget.eventContext.media.allMedia;
      if (currentMedia.isNotEmpty) {
        _selectedTemplateMedia = currentMedia.first;
      }
    }
  }

  bool get _canEditGallery =>
      widget.eventContext.isUserAuthor(widget.currentUID) ||
      widget.eventContext.isUserContributor(widget.currentUID);

  @override
  Widget build(BuildContext context) {
    final bodyMediaPool = widget.eventContext.templateBodyMediaPool;
    final hasTemplateMedia = bodyMediaPool != null && bodyMediaPool.isNotEmpty;
    final media = _getMedia();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_canEditGallery)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Material(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: _openEditGallery,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          Icon(Icons.photo_library_outlined, size: 20, color: colorScheme.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Edit gallery',
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            'Add or manage media',
                            style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (hasTemplateMedia) _buildTemplateMediaSelector(bodyMediaPool),
            Expanded(
              child: media.isEmpty
                  ? _buildEmptyMedia(theme, colorScheme)
                  : Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3, crossAxisSpacing: 4.0, mainAxisSpacing: 4.0),
                          itemCount: media.length,
                          itemBuilder: (itemContext, index) {
                            final Map<String, dynamic> entry = media[index];
                            if (entry['type']!.compareTo('img') == 0) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: ImageMediaSlot(
                                    mediaEntry: entry,
                                    onTap: () => _onMediaTap(index, itemContext),
                                    postID: widget.eventContext.id),
                              );
                            }
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: VideoMediaSlot(
                                  mediaEntry: entry,
                                  postId: widget.eventContext.id,
                                  onTap: () => _onMediaTap(index, itemContext)),
                            );
                          }),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyMedia(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_library_outlined, size: 48, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              'No media yet',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              _canEditGallery
                  ? 'Add images or videos to this post’s gallery.'
                  : 'Media for this post will appear here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            if (_canEditGallery) ...[
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: _openEditGallery,
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                label: const Text('Edit gallery'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openEditGallery() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditGalleryPage(eventContext: widget.eventContext)),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  Widget _buildTemplateMediaSelector(List<Map<String, dynamic>> templateMedia) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.all(8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.photo_library_outlined, size: 18, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  'Template Body Media Pool',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _pickRandomTemplateMedia(templateMedia),
                  icon: const Icon(Icons.shuffle, size: 18),
                  label: const Text('Random'),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(8.0),
              itemCount: templateMedia.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final item = templateMedia[index];
                final isSelected = _selectedTemplateMedia == item;
                return GestureDetector(
                  onTap: () => _selectTemplateMedia(item),
                  child: Container(
                    width: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
                        width: isSelected ? 2.5 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: _buildMediaThumbnail(item, colorScheme),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaThumbnail(Map<String, dynamic> item, ColorScheme colorScheme) {
    final type = item['type'] as String? ?? '';
    final thumbnailSrc = item['thumbnailSrc'] as String?;
    final src = item['src'] as String?;

    if (type == 'img' && src != null) {
      return Image.network(
        NetworkImageHelper.getImageUrl(src),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined),
      );
    }
    if (type == 'vid') {
      final thumbUrl = thumbnailSrc ?? src;
      if (thumbUrl != null) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              NetworkImageHelper.getImageUrl(thumbUrl),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: colorScheme.surfaceContainerHighest,
                child: Icon(Icons.videocam_outlined, color: colorScheme.onSurfaceVariant),
              ),
            ),
            const Align(
              alignment: Alignment.center,
              child: Icon(Icons.play_circle_outline, color: Colors.white, size: 24),
            ),
          ],
        );
      }
    }
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Icon(Icons.perm_media_outlined, color: colorScheme.onSurfaceVariant),
    );
  }

  void _selectTemplateMedia(Map<String, dynamic> item) {
    if (_selectedTemplateMedia == item) return;
    setState(() {
      if (_selectedTemplateMedia != null) {
        widget.eventContext.media.removeMediaFile(_selectedTemplateMedia!);
      }
      widget.eventContext.media.addMediaFile(item);
      _selectedTemplateMedia = item;
    });
  }

  void _pickRandomTemplateMedia(List<Map<String, dynamic>> templateMedia) {
    if (templateMedia.length <= 1) return;
    final random = Random();
    Map<String, dynamic> randomItem;
    do {
      randomItem = templateMedia[random.nextInt(templateMedia.length)];
    } while (randomItem == _selectedTemplateMedia);
    _selectTemplateMedia(randomItem);
  }

  // * Logic
  void _onMediaTap(final int index, final BuildContext context) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ViewGalleryPage(
                media: widget.eventContext.media.allMedia, initialIndex: index, postId: widget.eventContext.id)));
  }

  List<Map<String, dynamic>> _getMedia() {
    if (kIsWeb) {
      return widget.eventContext.media.allMedia.where((e) => e['type'] == 'img').toList();
    }
    return widget.eventContext.media.allMedia;
  }
}
