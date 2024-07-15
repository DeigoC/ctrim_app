import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../pages/view_gallery_page.dart';
import '../../utility/event_context.dart';
import '../media/image_media_slot.dart';
import '../media/video_media_slot.dart';

class ViewEventMediaTab extends StatelessWidget {
  const ViewEventMediaTab({super.key, required this.eventContext, required this.currentUID});
  final EventContext eventContext;
  final String currentUID;

  @override
  Widget build(BuildContext context) {
    final media = _getMedia();

    final List<Widget> children = [
      Expanded(
          child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, crossAxisSpacing: 2.0, mainAxisSpacing: 2.0),
              itemCount: media.length,
              itemBuilder: (_, index) {
                final Map<String, dynamic> entry = media[index];
                if (entry['type']!.compareTo('img') == 0) {
                  return ImageMediaSlot(mediaEntry: entry, onTap: () => _onMediaTap(index, _), postID: eventContext.id);
                }
                return VideoMediaSlot(mediaEntry: entry, postId: eventContext.id, onTap: () => _onMediaTap(index, _));
              }))
    ];

    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }

  // * Logic
  void _onMediaTap(final int index, final BuildContext context) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                ViewGalleryPage(media: eventContext.media.allMedia, initialIndex: index, postId: eventContext.id)));
  }

  List<Map<String, dynamic>> _getMedia() {
    if (kIsWeb) {
      return eventContext.media.allMedia.where((e) => e['type'] == 'img').toList();
    }
    return eventContext.media.allMedia;
  }
}
