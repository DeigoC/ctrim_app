import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../utility/dialog_manager.dart';
import '../../utility/event_context.dart';
import '../../widgets/media/image_media_slot.dart';
import '../../widgets/media/video_media_slot.dart';
import 'add_media_file_page.dart';

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
    _originalGallerySrcs = List<String>.from(widget.eventContext.media.allMedia.map<String>((e) => e['src']!).toList());
    _originalHeadSrcs = List<String>.from(widget.eventContext.head.media.map<String>((e) => e['src']!).toList());

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
    return PopScope(
        onPopInvoked: (_) {
          if (!widget.eventContext.canSaveTheEditing) {
            _shouldBeAbleToSave();
          }
        },
        child: Scaffold(
          body: _buildBody(),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _onAddMediaTap,
            label: const Text('Add Media'),
            icon: const Icon(Icons.add),
          ),
        ));
  }

  Widget _buildBody() {
    final double webHorizontalPadding =
        MediaQuery.of(context).size.width >= 768 ? MediaQuery.of(context).size.width / 7 : 0;

    return SafeArea(
      top: false,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(snap: true, floating: true, title: const Text('Edit Gallery')),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: webHorizontalPadding),
            sliver: SliverList(
                delegate: SliverChildListDelegate([
              ListTile(
                  title: const Text('Key Media'),
                  leading: const Icon(Icons.star),
                  trailing: IconButton(onPressed: _onKeyMediaHelpClick, icon: const Icon(Icons.help))),
              const Divider(thickness: 1),
              for (int i = 0; i < widget.eventContext.head.media.length; i++)
                _buildMediaBox(widget.eventContext.head.media[i], true),
              const SizedBox(height: 32),
              ListTile(
                  title: const Text('Post Media'),
                  leading: const Icon(Icons.photo_library),
                  trailing: IconButton(onPressed: _onPostMediaHelpClick, icon: const Icon(Icons.help))),
              const Divider(thickness: 1),
            ])),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: webHorizontalPadding),
            sliver: SliverList.separated(
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemCount: widget.eventContext.media.allMedia.length,
                itemBuilder: (_, index) {
                  final Map<String, dynamic> thisEntry = widget.eventContext.media.allMedia[index];
                  return _buildMediaBox(thisEntry, false);
                }),
          )
        ],
      ),
    );
  }

  Widget _buildMediaBox(final Map<String, dynamic> thisEntry, final bool isKey) {
    final bool isPartOfHead = !isKey && widget.eventContext.head.containsMediaItem(thisEntry['src']!);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      elevation: 2,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Stack(
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12.0)),
                child: _buildMediaViewer(thisEntry, isKey),
              ),
            ),
            // Quick action buttons overlay
            Positioned(
              top: 8,
              right: 8,
              child: _buildQuickActions(thisEntry, isKey),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isPartOfHead || isKey)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, size: 14, color: Colors.amber[700]),
                          const SizedBox(width: 4),
                          Text('Key Media', style: TextStyle(fontSize: 12, color: Colors.amber[700])),
                        ],
                      ),
                    ),
                  const Spacer(),
                  // Quick caption edit
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _onEditMediaEntry(thisEntry),
                    tooltip: 'Edit Caption',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                thisEntry['title']!.isEmpty ? 'No caption' : thisEntry['title']!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontStyle: thisEntry['title']!.isEmpty ? FontStyle.italic : FontStyle.normal,
                      color: thisEntry['title']!.isEmpty ? Colors.grey : null,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                thisEntry['src']!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildMediaViewer(final Map<String, dynamic> thisEntry, final bool isKey) {
    if (thisEntry['type']!.compareTo('img') == 0) {
      return ImageMediaSlot(
        mediaEntry: thisEntry,
        onTap: null,
        postID: isKey ? 'key' : 'media',
      );
    }
    return VideoMediaSlot(postId: widget.eventContext.id, mediaEntry: thisEntry, onTap: null);
  }

  Widget _buildQuickActions(final Map<String, dynamic> thisEntry, final bool isKey) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Star/Unstar action for non-key media
          if (!isKey && _canBeKeyMedia(thisEntry['src']!))
            IconButton(
              icon: const Icon(Icons.star_border, color: Colors.white, size: 20),
              onPressed: () => _addMediaAsKeyClick(thisEntry),
              tooltip: 'Set as Key Media',
            ),

          // Remove from key media (for key media items)
          if (isKey)
            IconButton(
              icon: const Icon(Icons.star, color: Colors.amber, size: 20),
              onPressed: () => _deleteMediaClick(thisEntry, isKey),
              tooltip: 'Remove Key Media',
            ),

          // Video thumbnail edit (for videos only)
          if (thisEntry['type'] == 'vid')
            IconButton(
              icon: const Icon(Icons.video_settings, color: Colors.white, size: 20),
              onPressed: () => _onEditVideoThumbnailClick(thisEntry),
              tooltip: 'Edit Thumbnail',
            ),

          // Delete action
          if (!isKey)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed: () => _deleteMediaClick(thisEntry, isKey),
              tooltip: 'Delete',
            ),
        ],
      ),
    );
  }

  // * Logic

  void _onAddMediaTap() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => AddMediaFilePage(
                  eventContext: widget.eventContext,
                ))).then((_) {
      setState(() {});
    });
  }

  bool _canBeKeyMedia(final String src) {
    return widget.eventContext.head.media.length < 4 &&
        !widget.eventContext.head.media.map<String>((e) => e['src']!).toList().contains(src);
  }

  void _shouldBeAbleToSave() {
    if (_originalGallerySrcs.length != widget.eventContext.media.allMedia.length ||
        _originalHeadSrcs.length != widget.eventContext.head.media.length) {
      widget.eventContext.allowSavingOfTheEdit();
      return;
    }

    for (final String src in widget.eventContext.media.allMedia.map<String>((e) => e['src']!).toList()) {
      if (!_originalGallerySrcs.contains(src)) {
        widget.eventContext.allowSavingOfTheEdit();
        return;
      } else if (_originalGalleryCaptions.containsKey(src) &&
          _originalGalleryCaptions[src] !=
              widget.eventContext.media.allMedia.firstWhere((e) => e.containsValue(src))['title']) {
        widget.eventContext.allowSavingOfTheEdit();
        return;
      }
    }

    for (final String src in widget.eventContext.head.media.map<String>((e) => e['src']!).toList()) {
      if (!_originalHeadSrcs.contains(src)) {
        widget.eventContext.allowSavingOfTheEdit();
        return;
      } else if (_originalHeadCaptions.containsKey(src) &&
          _originalHeadCaptions[src] !=
              widget.eventContext.head.media.firstWhere((e) => e.containsValue(src))['title']) {
        widget.eventContext.allowSavingOfTheEdit();
        return;
      }
    }
  }

  void _addMediaAsKeyClick(final Map<String, dynamic> thisEntry) {
    setState(() {
      widget.eventContext.head
          .addMediaItem(type: thisEntry['type']!, src: thisEntry['src']!, title: thisEntry['title']!);
    });
  }

  void _deleteMediaClick(final Map<String, dynamic> thisEntry, final bool isKey) {
    DialogManager.showConfirmationDialog(
            context: context, title: 'Delete Media Item', content: 'Are you sure you want to continue?')
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
    showDialog(
        context: context,
        builder: (_) => Dialog(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        decoration: const InputDecoration(label: Text('Caption'), hintText: 'Optional...'),
                        maxLength: 32,
                        controller: TextEditingController(text: thisEntry['title']),
                        onChanged: (newText) => thisEntry['title'] = newText,
                      )
                    ],
                  ),
                ),
              ),
            )).then((_) {
      setState(() {});
    });
  }

  void _onKeyMediaHelpClick() {
    DialogManager.showAlertDialog(
        context: context,
        title: 'Key Media',
        content:
            'First image will be set as the key graphic for the post. These will also be displayed for the post thumnbnail.');
  }

  void _onPostMediaHelpClick() {
    DialogManager.showAlertDialog(
        context: context,
        title: 'Post Media',
        content: 'Your go-to images and videos for the post. Remember that you can write captions if you wish to.');
  }

  void _onEditVideoThumbnailClick(final Map<String, dynamic> thisEntry) {
    debugPrint("current thumbnail is ${thisEntry['thumbnailSrc']}");
    showDialog(
        context: context,
        barrierDismissible: false,
        barrierLabel: 'Edit Thumbnail Src',
        builder: (_) => VideoThumbnailEditDialog(thisEntry: thisEntry, postId: widget.eventContext.id)).then((_) {
      setState(() {
        debugPrint("new thumbnail src is ${thisEntry['thumbnailSrc']}");
        // ! bear in mind there's that issue where you don't actually see the new image at first
        widget.eventContext.allowSavingOfTheEdit(); // just blindly allow it for now
      });
    });
  }
}

class VideoThumbnailEditDialog extends StatefulWidget {
  const VideoThumbnailEditDialog({super.key, required this.thisEntry, required this.postId});
  final Map<String, dynamic> thisEntry;
  final String postId;

  @override
  State<VideoThumbnailEditDialog> createState() => _VideoThumbnailEditDialogState();
}

class _VideoThumbnailEditDialogState extends State<VideoThumbnailEditDialog> {
  late final TextEditingController _tecThumbnailSrc;

  @override
  void initState() {
    final String src = widget.thisEntry['thumbnailSrc'] ?? '';
    debugPrint('src at init is $src');
    _tecThumbnailSrc = TextEditingController(text: widget.thisEntry['thumbnailSrc']);
    super.initState();
  }

  @override
  void dispose() {
    _tecThumbnailSrc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: _tecThumbnailSrc,
            decoration: InputDecoration(
                hintText: 'https://...',
                label: const Text('Video Thumbnail'),
                suffixIcon: IconButton(onPressed: _onClearThumbnailSrc, icon: const Icon(Icons.clear))),
          ),
          const SizedBox(height: 8),
          TextButton(
              child: const Text('Close'),
              onPressed: () {
                _deleteOldThumbnail().then((_) {
                  widget.thisEntry['thumbnailSrc'] = _tecThumbnailSrc.text;
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                });
              })
        ]),
      ),
    );
  }

  void _onClearThumbnailSrc() {
    setState(() {
      _tecThumbnailSrc.clear();
    });
  }

  Future<void> _deleteOldThumbnail() async {
    final String src = widget.thisEntry['src']!;
    final String title = src.replaceAll(RegExp(r'[^\w]'), '');
    final String path = '${(await getApplicationDocumentsDirectory()).path}/posts/${widget.postId}/$title.webp';
    final File imgFile = File(path);

    if (await imgFile.exists()) {
      debugPrint('deleting old thumbnail: ${imgFile.path}');
      await imgFile.delete();
    }
  }
}
