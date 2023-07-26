import 'package:ctrim_app/firebase/db_managers/event_db_manager.dart';
import 'package:ctrim_app/models/event/event_media.dart';
import 'package:ctrim_app/pages/events/edit_gallery_page.dart';
import 'package:ctrim_app/utility/event_context.dart';
import 'package:ctrim_app/widgets/media/image_media_slot.dart';
import 'package:ctrim_app/widgets/media/video_media_slot.dart';
import 'package:flutter/material.dart';

import '../../pages/view_gallery_page.dart';

class ViewEventMediaTab extends StatelessWidget {
  const ViewEventMediaTab({super.key, required this.eventContext, required this.onMediaEdit, required this.currentUID});
  final EventContext eventContext;
  final Function onMediaEdit;
  final String currentUID;

  @override
  Widget build(BuildContext context) {
    if (eventContext.fethcedMedia) {
      return _buildWithData(context);
    }
    return FutureBuilder(
        future: _fetchMedia(),
        builder: (_, snap) {
          Widget result = const Center(child: CircularProgressIndicator());

          if (snap.hasData) {
            eventContext.setFetchedMedia(snap.data!);
            result = _buildWithData(_);
          } else if (snap.hasError) {
            debugPrint('Something with the post media tab: ${snap.error}');
            result = const Center(child: Text('Something went wrong!'));
          }

          return result;
        });
  }

  Widget _buildWithData(final BuildContext context) {
    if (eventContext.media.allMedia.isEmpty) {
      return _buildNoMediaBody();
    }
    return _buildMediaGrid(context);
  }

  Widget _buildMediaGrid(final BuildContext context) {
    final List<Widget> children = [
      Expanded(
          child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, crossAxisSpacing: 2.0, mainAxisSpacing: 2.0),
              itemCount: eventContext.media.allMedia.length,
              itemBuilder: (_, index) {
                final Map<String, String> entry = eventContext.media.allMedia[index];
                if (entry['type']!.compareTo('img') == 0) {
                  return ImageMediaSlot(mediaEntry: entry, onTap: () => _onMediaTap(index, _));
                }
                return VideoMediaSlot(mediaEntry: entry, onTap: () => _onMediaTap(index, _));
              }))
    ];

    if (eventContext.isCurrentUserAuthor(currentUID) || eventContext.isCurrentUserContributor(currentUID)) {
      children.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ElevatedButton.icon(
              onPressed: () => _onEditMediaTap(context),
              label: const Text('Edit Media Items'),
              icon: const Icon(Icons.photo_album))));
    }

    return SafeArea(
      top: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildNoMediaBody() {
    return const Center(child: Text('No media files!'));
  }

  // * Logic

  void _onEditMediaTap(final BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => EditGalleryPage(eventContext: eventContext)))
        .then((_) => onMediaEdit());
  }

  void _onMediaTap(final int index, final BuildContext context) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                ViewGalleryPage(media: eventContext.media.allMedia, initialIndex: index, postId: eventContext.id)));
  }

  Future<EventMedia> _fetchMedia() {
    final EventSupplementalDBManager manager = EventSupplementalDBManager(eventContext.id);
    return manager.fetchMedia();
  }
}
