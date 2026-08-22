import 'package:flutter/material.dart';

import '../../utility/dialog_manager.dart';
import '../../utility/event_context.dart';
import '../../utility/local_data_manager.dart';
import '../../widgets/media/image_media_slot.dart';
import '../../widgets/media/video_media_slot.dart';
import '../../widgets/app_dialog.dart';
import 'add_media_file_page.dart';
import 'select_template_cover_page.dart';
import '../../utility/responsive_layout.dart';

class EditGalleryPage extends StatefulWidget {
  const EditGalleryPage({super.key, required this.eventContext});
  final EventContext eventContext;

  @override
  State<EditGalleryPage> createState() => _EditGalleryPageState();
}

class _EditGalleryPageState extends State<EditGalleryPage> {
  late final List<String> _originalGallerySrcs;
  late final List<String> _originalHeadSrcs;
  final Map<String, String> _originalGalleryCaptions = {};
  final Map<String, String> _originalHeadCaptions = {};

  @override
  void initState() {
    _originalGallerySrcs = List<String>.from(widget.eventContext.media.allMedia
        .map<String>((e) => e['src']!)
        .toList());
    _originalHeadSrcs = List<String>.from(
        widget.eventContext.head.media.map<String>((e) => e['src']!).toList());

    for (var entry in widget.eventContext.media.allMedia) {
      _originalGalleryCaptions[entry['src']!] = entry['title']!;
    }
    for (var entry in widget.eventContext.head.media) {
      _originalHeadCaptions[entry['src']!] = entry['title']!;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
        onPopInvokedWithResult: (didPop, result) {
          if (!widget.eventContext.canSaveTheEditing) {
            _shouldBeAbleToSave();
          }
        },
        child: Scaffold(
          backgroundColor: colorScheme.surface,
          body: _buildBody(),
        ));
  }

  Widget _buildBody() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final double webHorizontalPadding = ResponsiveLayout.horizontalGutter(
        MediaQuery.sizeOf(context).width,
        narrowPadding: 16);

    return SafeArea(
      top: false,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            snap: true,
            floating: true,
            title: const Text('Edit Gallery'),
            backgroundColor: colorScheme.surface,
            foregroundColor: colorScheme.onSurface,
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(
                horizontal: webHorizontalPadding, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Key Media Section
                Card(
                  elevation: 0,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                        color: colorScheme.outline.withValues(alpha: 0.12)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.star,
                                color: colorScheme.onPrimaryContainer,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Key Media',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${widget.eventContext.head.media.length}/4 items · shown on the post card',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _onKeyMediaHelpClick,
                              icon: Icon(
                                Icons.help_outline,
                                color: colorScheme.primary,
                              ),
                              tooltip: 'Learn about Key Media',
                            ),
                          ],
                        ),
                        if (widget.eventContext.head.media.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          ...widget.eventContext.head.media.asMap().entries.map(
                                (entry) => Padding(
                                  padding: EdgeInsets.only(
                                      bottom: entry.key <
                                              widget.eventContext.head.media
                                                      .length -
                                                  1
                                          ? 12
                                          : 0),
                                  child: _buildMediaBox(entry.value, true),
                                ),
                              ),
                        ] else ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color:
                                    colorScheme.outline.withValues(alpha: 0.3),
                              ),
                              borderRadius: BorderRadius.circular(12),
                              color: colorScheme.surface,
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.star_border,
                                  size: 48,
                                  color: colorScheme.onSurface
                                      .withValues(alpha: 0.4),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No Key Media Yet',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Choose a cover from a template pool, or add media below and mark it as key',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _onChooseTemplateCover,
                          icon: const Icon(Icons.photo_library_outlined,
                              size: 18),
                          label: const Text('Choose from template cover pool'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Post Media Section header + add actions
                Card(
                  elevation: 0,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                        color: colorScheme.outline.withValues(alpha: 0.12)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.photo_library,
                                color: colorScheme.onSecondaryContainer,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Post Media',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${widget.eventContext.media.allMedia.length} items · gallery on the Media tab',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _onPostMediaHelpClick,
                              icon: Icon(
                                Icons.help_outline,
                                color: colorScheme.primary,
                              ),
                              tooltip: 'Learn about Post Media',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _onAddMediaTap(initialIsVideo: false),
                                icon:
                                    const Icon(Icons.image_outlined, size: 18),
                                label: const Text('Add image'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _onAddMediaTap(initialIsVideo: true),
                                icon: const Icon(Icons.videocam_outlined,
                                    size: 18),
                                label: const Text('Add video'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ),
          // Post Media list
          if (widget.eventContext.media.allMedia.isEmpty)
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: webHorizontalPadding),
              sliver: SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(16),
                    color: colorScheme.surfaceContainerLow,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 64,
                        color: colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Media Files Yet',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add an image or video from a URL (Google Drive links work too).',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: webHorizontalPadding),
              sliver: SliverList.separated(
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemCount: widget.eventContext.media.allMedia.length,
                itemBuilder: (_, index) {
                  final Map<String, dynamic> thisEntry =
                      widget.eventContext.media.allMedia[index];
                  return _buildMediaBox(thisEntry, false);
                },
              ),
            ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaBox(
      final Map<String, dynamic> thisEntry, final bool isKey) {
    final bool isPartOfHead =
        !isKey && widget.eventContext.head.containsMediaItem(thisEntry['src']!);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color:
                Theme.of(context).colorScheme.outline.withValues(alpha: 0.12)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.3),
                  ),
                  child: _buildMediaViewer(thisEntry, isKey),
                ),
              ),
              // Gradient overlay for better button visibility
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.center,
                      colors: [
                        Colors.black.withValues(alpha: 0.6),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.7],
                    ),
                  ),
                ),
              ),
              // Quick action buttons overlay
              Positioned(
                top: 12,
                right: 12,
                child: _buildQuickActions(thisEntry, isKey),
              ),
              // Media type indicator
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        thisEntry['type'] == 'vid'
                            ? Icons.videocam
                            : Icons.image,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        thisEntry['type'] == 'vid' ? 'Video' : 'Image',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isPartOfHead || isKey)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              size: 14,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Key Media',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Spacer(),
                    // Quick caption edit
                    IconButton(
                      icon: Icon(
                        Icons.edit_outlined,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () => _onEditMediaEntry(thisEntry),
                      tooltip: 'Edit Caption',
                      style: IconButton.styleFrom(
                        minimumSize: const Size(32, 32),
                        padding: const EdgeInsets.all(4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  thisEntry['title']!.isEmpty
                      ? 'No caption added'
                      : thisEntry['title']!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontStyle: thisEntry['title']!.isEmpty
                            ? FontStyle.italic
                            : FontStyle.normal,
                        color: thisEntry['title']!.isEmpty
                            ? Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5)
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: thisEntry['title']!.isEmpty
                            ? FontWeight.normal
                            : FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    thisEntry['src']!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontFamily: 'monospace',
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaViewer(
      final Map<String, dynamic> thisEntry, final bool isKey) {
    if (thisEntry['type']!.compareTo('img') == 0) {
      return ImageMediaSlot(
        key: ValueKey('${isKey ? 'key' : 'media'}-${thisEntry['src']}'),
        mediaEntry: thisEntry,
        onTap: null,
        postID: isKey ? 'key' : 'media',
      );
    }
    return VideoMediaSlot(
        postId: widget.eventContext.id, mediaEntry: thisEntry, onTap: null);
  }

  Widget _buildQuickActions(
      final Map<String, dynamic> thisEntry, final bool isKey) {
    final List<Widget> actions = [];

    // Star/Unstar action for non-key media
    if (!isKey && _canBeKeyMedia(thisEntry['src']!)) {
      actions.add(
        _buildActionButton(
          icon: Icons.star_border,
          color: Colors.amber,
          onPressed: () => _addMediaAsKeyClick(thisEntry),
          tooltip: 'Set as Key Media',
        ),
      );
    }

    // Remove from key media (for key media items)
    if (isKey) {
      actions.add(
        _buildActionButton(
          icon: Icons.star,
          color: Colors.amber,
          onPressed: () => _deleteMediaClick(thisEntry, isKey),
          tooltip: 'Remove from Key Media',
        ),
      );
    }

    // Video thumbnail edit (for videos only)
    if (thisEntry['type'] == 'vid') {
      actions.add(
        _buildActionButton(
          icon: Icons.video_settings,
          color: Colors.blue,
          onPressed: () => _onEditVideoThumbnailClick(thisEntry),
          tooltip: 'Edit Video Thumbnail',
        ),
      );
    }

    // Delete action
    if (!isKey) {
      actions.add(
        _buildActionButton(
          icon: Icons.delete_outline,
          color: Colors.red,
          onPressed: () => _deleteMediaClick(thisEntry, isKey),
          tooltip: 'Delete Media',
        ),
      );
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Column(
      children: actions
          .map((action) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: action,
              ))
          .toList(),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 18),
        onPressed: onPressed,
        tooltip: tooltip,
        constraints: const BoxConstraints(
          minWidth: 36,
          minHeight: 36,
        ),
        padding: const EdgeInsets.all(6),
      ),
    );
  }

  // * Logic

  void _onAddMediaTap({bool initialIsVideo = false}) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => AddMediaFilePage(
                  eventContext: widget.eventContext,
                  initialIsVideo: initialIsVideo,
                ))).then((_) {
      setState(() {});
    });
  }

  Future<void> _onChooseTemplateCover() async {
    final selected = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectTemplateCoverPage(
          preferredTitle: widget.eventContext.head.title,
          preferredLocation: widget.eventContext.head.location,
        ),
      ),
    );
    if (!mounted || selected == null) return;

    setState(() {
      widget.eventContext.head.replaceKeyGraphic(
        type: selected['type'] ?? 'img',
        src: selected['src'] ?? '',
        title: selected['title'] ?? '',
        thumbnail: selected['thumbnailSrc'] ?? '',
      );
    });
    widget.eventContext.allowSavingOfTheEdit();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content:
              Text('Key graphic updated — save the post to keep the change')),
    );
  }

  bool _canBeKeyMedia(final String src) {
    return widget.eventContext.head.media.length < 4 &&
        !widget.eventContext.head.media
            .map<String>((e) => e['src']!)
            .toList()
            .contains(src);
  }

  void _shouldBeAbleToSave() {
    if (_originalGallerySrcs.length !=
            widget.eventContext.media.allMedia.length ||
        _originalHeadSrcs.length != widget.eventContext.head.media.length) {
      widget.eventContext.allowSavingOfTheEdit();
      return;
    }

    for (final String src in widget.eventContext.media.allMedia
        .map<String>((e) => e['src']!)
        .toList()) {
      if (!_originalGallerySrcs.contains(src)) {
        widget.eventContext.allowSavingOfTheEdit();
        return;
      } else if (_originalGalleryCaptions.containsKey(src) &&
          _originalGalleryCaptions[src] !=
              widget.eventContext.media.allMedia
                  .firstWhere((e) => e.containsValue(src))['title']) {
        widget.eventContext.allowSavingOfTheEdit();
        return;
      }
    }

    for (final String src in widget.eventContext.head.media
        .map<String>((e) => e['src']!)
        .toList()) {
      if (!_originalHeadSrcs.contains(src)) {
        widget.eventContext.allowSavingOfTheEdit();
        return;
      } else if (_originalHeadCaptions.containsKey(src) &&
          _originalHeadCaptions[src] !=
              widget.eventContext.head.media
                  .firstWhere((e) => e.containsValue(src))['title']) {
        widget.eventContext.allowSavingOfTheEdit();
        return;
      }
    }
  }

  void _addMediaAsKeyClick(final Map<String, dynamic> thisEntry) {
    setState(() {
      // Prepend so getKeyGraphic / bulletin thumbnail use this item (first image wins).
      widget.eventContext.head.prependMediaItem(
        type: thisEntry['type']!,
        src: thisEntry['src']!,
        title: thisEntry['title'] ?? '',
        thumbnail: thisEntry['thumbnailSrc'] ?? '',
      );
    });
    widget.eventContext.allowSavingOfTheEdit();
  }

  void _deleteMediaClick(
      final Map<String, dynamic> thisEntry, final bool isKey) {
    DialogManager.showConfirmationDialog(
            context: context,
            title: 'Delete Media Item',
            content: 'Are you sure you want to continue?')
        .then((confirmation) {
      if (confirmation) {
        setState(() {
          if (isKey) {
            widget.eventContext.head.removeMediaItem(thisEntry);
          } else {
            widget.eventContext.media.removeMediaFile(thisEntry);
          }
        });
      }
    });
  }

  void _onEditMediaEntry(final Map<String, dynamic> thisEntry) {
    final TextEditingController captionController =
        TextEditingController(text: thisEntry['title']);

    showDialog(
      context: context,
      builder: (context) => AppDialog(
        icon: Icons.edit_outlined,
        title: 'Edit Caption',
        message:
            'Add a caption to describe this ${thisEntry['type'] == 'vid' ? 'video' : 'image'}',
        child: TextField(
          controller: captionController,
          decoration: AppDialog.inputDecoration(
            label: 'Caption',
            hint: 'Enter a descriptive caption...',
            prefixIcon: const Icon(Icons.title),
            maxLines: 2,
          ),
          maxLength: 32,
          maxLines: 2,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (newText) => thisEntry['title'] = newText,
        ),
        actions: AppDialogActions(
          onCancel: () => Navigator.of(context).pop(),
          onConfirm: () {
            thisEntry['title'] = captionController.text.trim();
            Navigator.of(context).pop();
            setState(() {});
          },
          confirmLabel: 'Save',
        ),
      ),
    ).then((_) {
      captionController.dispose();
    });
  }

  void _onKeyMediaHelpClick() {
    DialogManager.showAlertDialog(
      context: context,
      icon: Icons.star_outline,
      title: 'Key Media',
      content:
          'Key media are the most important images and videos for your event.\n\n'
          '• First image becomes the event thumbnail\n'
          '• Displayed prominently in event previews\n'
          '• Maximum of 4 key media items\n'
          '• Can be images or videos',
    );
  }

  void _onPostMediaHelpClick() {
    DialogManager.showAlertDialog(
      context: context,
      icon: Icons.photo_library_outlined,
      title: 'Post Media',
      content: 'All images and videos associated with your event.\n\n'
          '• Add captions to describe your media\n'
          '• Mark important items as key media\n'
          '• Videos can have custom thumbnails\n'
          '• Organize your media gallery',
    );
  }

  void _onEditVideoThumbnailClick(final Map<String, dynamic> thisEntry) {
    debugPrint("current thumbnail is ${thisEntry['thumbnailSrc']}");
    showDialog(
        context: context,
        barrierDismissible: false,
        barrierLabel: 'Edit Thumbnail Src',
        builder: (_) => VideoThumbnailEditDialog(
            thisEntry: thisEntry, postId: widget.eventContext.id)).then((_) {
      setState(() {
        debugPrint("new thumbnail src is ${thisEntry['thumbnailSrc']}");
        // ! bear in mind there's that issue where you don't actually see the new image at first
        widget.eventContext
            .allowSavingOfTheEdit(); // just blindly allow it for now
      });
    });
  }
}

class VideoThumbnailEditDialog extends StatefulWidget {
  const VideoThumbnailEditDialog(
      {super.key, required this.thisEntry, required this.postId});
  final Map<String, dynamic> thisEntry;
  final String postId;

  @override
  State<VideoThumbnailEditDialog> createState() =>
      _VideoThumbnailEditDialogState();
}

class _VideoThumbnailEditDialogState extends State<VideoThumbnailEditDialog> {
  late final TextEditingController _tecThumbnailSrc;

  @override
  void initState() {
    final String src = widget.thisEntry['thumbnailSrc'] ?? '';
    debugPrint('src at init is $src');
    _tecThumbnailSrc =
        TextEditingController(text: widget.thisEntry['thumbnailSrc']);
    super.initState();
  }

  @override
  void dispose() {
    _tecThumbnailSrc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      icon: Icons.image_outlined,
      title: 'Video thumbnail',
      message: 'Paste a public image URL used as the video preview.',
      child: TextField(
        controller: _tecThumbnailSrc,
        decoration: AppDialog.inputDecoration(
          label: 'Thumbnail URL',
          hint: 'https://...',
          suffixIcon: IconButton(
            onPressed: _onClearThumbnailSrc,
            icon: const Icon(Icons.clear),
          ),
        ),
      ),
      actions: AppDialogActions(
        onConfirm: () {
          _deleteOldThumbnail().then((_) {
            if (!context.mounted) return;
            widget.thisEntry['thumbnailSrc'] = _tecThumbnailSrc.text;
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          });
        },
        confirmLabel: 'Save',
      ),
    );
  }

  void _onClearThumbnailSrc() {
    setState(() {
      _tecThumbnailSrc.clear();
    });
  }

  Future<void> _deleteOldThumbnail() async {
    final localDataManager = LocalDataManager();
    final String src = widget.thisEntry['src']!;
    final String videoKey = src.replaceAll(RegExp(r'[^\w]'), '');

    debugPrint('Deleting old video thumbnail for: ${widget.postId}/$videoKey');
    await localDataManager.deleteVideoThumbnail(widget.postId, videoKey);
  }
}
