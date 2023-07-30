import 'package:ctrim_app/pages/events/add_media_file_page.dart';
import 'package:ctrim_app/utility/dialog_manager.dart';
import 'package:ctrim_app/utility/event_context.dart';
import 'package:ctrim_app/widgets/media/image_media_slot.dart';
import 'package:ctrim_app/widgets/media/video_media_slot.dart';
import 'package:flutter/material.dart';

class EditGalleryPage extends StatefulWidget {
  const EditGalleryPage({super.key, required this.eventContext});
  final EventContext eventContext;

  @override
  State<EditGalleryPage> createState() => _EditGalleryPageState();
}

class _EditGalleryPageState extends State<EditGalleryPage> {
  late final List<String> _originalGallerySrcs;
  late final List<String> _originalHeadSrcs;

  @override
  void initState() {
    _originalGallerySrcs = List<String>.from(widget.eventContext.media.allMedia.map<String>((e) => e['src']!).toList());
    _originalHeadSrcs = List<String>.from(widget.eventContext.head.media.map<String>((e) => e['src']!).toList());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          if (!widget.eventContext.canSaveTheEditing) {
            _shouldBeAbleToSave();
          }
          return true;
        },
        child: Scaffold(body: _buildBody()));
  }

  Widget _buildBody() {
    return SafeArea(
      top: false,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
              snap: true,
              floating: true,
              title: const Text('Edit Gallery'),
              actions: [IconButton(onPressed: _onAddMediaTap, icon: const Icon(Icons.add_photo_alternate))]),
          SliverList(
              delegate: SliverChildListDelegate([
            const Divider(thickness: 1),
            const Text('Key Media'),
            const Divider(thickness: 1),
            for (int i = 0; i < widget.eventContext.head.media.length; i++)
              Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: _buildMediaBox(widget.eventContext.head.media[i], true)),
            const Divider(thickness: 1),
            const Text('Post Media'),
            const Divider(thickness: 1)
          ])),
          SliverList.separated(
              separatorBuilder: (_, __) => const Divider(),
              itemCount: widget.eventContext.media.allMedia.length,
              itemBuilder: (_, index) {
                final Map<String, String> thisEntry = widget.eventContext.media.allMedia[index];
                return _buildMediaBox(thisEntry, false);
              })
        ],
      ),
    );
  }

  Widget _buildMediaBox(final Map<String, String> thisEntry, final bool isKey) {
    bool isPartOfHead = !isKey && widget.eventContext.head.containsMediaItem(thisEntry['src']!);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: _buildMediaViewer(thisEntry, isKey),
        ),
      ),
      ListTile(
          title: Text(thisEntry['title']!),
          subtitle: Text(thisEntry['src']!, maxLines: 2, overflow: TextOverflow.ellipsis),
          leading: isPartOfHead ? const Icon(Icons.star) : null,
          trailing:
              IconButton(onPressed: () => _showSettingsForMedia(thisEntry, isKey), icon: const Icon(Icons.more_vert)))
    ]);
  }

  Widget _buildMediaViewer(final Map<String, String> thisEntry, bool isKey) {
    if (thisEntry['type']!.compareTo('img') == 0) {
      return ImageMediaSlot(
        mediaEntry: thisEntry,
        onTap: null,
        heroPrefix: isKey ? 'key' : 'media',
      );
    }
    return VideoMediaSlot(mediaEntry: thisEntry, onTap: null);
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

  void _showSettingsForMedia(final Map<String, String> thisEntry, final bool isKey) {
    final List<Widget> children = [
      ListTile(
          title: isKey ? const Text('Remove Key Media') : const Text('Delete'),
          onTap: () => _deleteMediaClick(thisEntry, isKey),
          trailing: const Icon(
            Icons.delete,
            color: Colors.red,
          ))
    ];

    if (!isKey && _canBeKeyMedia(thisEntry['src']!)) {
      children.insert(
          0,
          ListTile(
              title: const Text('Set as key media'),
              trailing: const Icon(Icons.star),
              onTap: () => _addMediaAsKeyClick(thisEntry)));
    }

    showModalBottomSheet(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32.0),
        ),
        context: context,
        showDragHandle: true,
        builder: (_) => SafeArea(child: SingleChildScrollView(child: Column(children: children))));
  }

  bool _canBeKeyMedia(String src) {
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
      }
    }

    for (final String src in widget.eventContext.head.media.map<String>((e) => e['src']!).toList()) {
      if (!_originalHeadSrcs.contains(src)) {
        widget.eventContext.allowSavingOfTheEdit();
        return;
      }
    }
  }

  void _addMediaAsKeyClick(final Map<String, String> thisEntry) {
    setState(() {
      Navigator.of(context).pop();
      widget.eventContext.head.addMediaItem(thisEntry);
    });
  }

  void _deleteMediaClick(final Map<String, String> thisEntry, final bool isKey) {
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

          Navigator.of(context).pop();
        });
      }
    });
  }
}
