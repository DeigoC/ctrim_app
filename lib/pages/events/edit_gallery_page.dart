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
            ListTile(
                title: const Text('Key Media'),
                leading: const Icon(Icons.star),
                trailing: IconButton(onPressed: _onKeyMediaHelpClick, icon: const Icon(Icons.help))),
            const Divider(thickness: 1),
            const SizedBox(height: 16),
            for (int i = 0; i < widget.eventContext.head.media.length; i++)
              Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: _buildMediaBox(widget.eventContext.head.media[i], true)),
            const SizedBox(height: 8),
            const Divider(thickness: 1),
            ListTile(
                title: const Text('Post Media'),
                leading: const Icon(Icons.photo_library),
                trailing: IconButton(onPressed: _onPostMediaHelpClick, icon: const Icon(Icons.help))),
            const Divider(thickness: 1),
            const SizedBox(height: 16),
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
      const SizedBox(height: 8),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: _buildMediaViewer(thisEntry, isKey),
        ),
      ),
      ListTile(
          title: Text(thisEntry['title']!),
          subtitle: Text(thisEntry['src']!, maxLines: 1, overflow: TextOverflow.ellipsis),
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
        postID: isKey ? 'key' : 'media',
      );
    }
    return VideoMediaSlot(postId: widget.eventContext.id, mediaEntry: thisEntry, onTap: null);
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
        title: const Text('Edit Caption'),
        trailing: const Icon(Icons.edit),
        onTap: () => _onEditMediaEntry(thisEntry),
      ),
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

  void _addMediaAsKeyClick(final Map<String, String> thisEntry) {
    setState(() {
      Navigator.of(context).pop();
      widget.eventContext.head
          .addMediaItem(type: thisEntry['type']!, src: thisEntry['src']!, title: thisEntry['title']!);
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

  void _onEditMediaEntry(final Map<String, String> thisEntry) {
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
      Navigator.of(context).pop();
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
}
