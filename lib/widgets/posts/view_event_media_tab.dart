import 'package:ctrim_app/firebase/db_managers/event_db_manager.dart';
import 'package:ctrim_app/models/event/event_media.dart';
import 'package:ctrim_app/utility/event_context.dart';
import 'package:ctrim_app/widgets/media/image_media_slot.dart';
import 'package:ctrim_app/widgets/media/video_media_slot.dart';
import 'package:flutter/material.dart';

import '../../pages/view_gallery_page.dart';

class ViewEventMediaTab extends StatelessWidget {
  const ViewEventMediaTab({super.key, required this.eventContext});
  final EventContext eventContext;

  @override
  Widget build(BuildContext context) {
    if (eventContext.fethcedMedia) {
      return _buildWithData();
    }
    return FutureBuilder(
        future: _fetchMedia(),
        builder: (_, snap) {
          Widget result = const Center(
            child: CircularProgressIndicator(),
          );

          if (snap.hasData) {
            eventContext.setFetchedMedia(snap.data!);
            result = _buildWithData();
          } else if (snap.hasError) {
            debugPrint('Something with the post media tab: ${snap.error}');
            result = const Center(
              child: Text('Something went wrong!'),
            );
          }

          return result;
        });
  }

  Widget _buildWithData() {
    if (eventContext.media.allMedia.isEmpty) {
      return _buildNoMediaBody();
    }
    return _buildMediaGrid();
  }

  Widget _buildMediaGrid() {
    return GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
        itemCount: eventContext.media.allMedia.length,
        itemBuilder: (_, index) {
          final Map<String, String> entry = eventContext.media.allMedia[index];
          if (entry['type']!.compareTo('img') == 0) {
            return ImageMediaSlot(mediaEntry: entry, onTap: () => _onMediaTap(index, _));
          }
          return VideoMediaSlot(mediaEntry: entry, onTap: () => _onMediaTap(index, _));
        });
  }

  Widget _buildNoMediaBody() {
    return const Center(
      child: Text('No media files!'),
    );
  }

  // * Logic

  void _onMediaTap(int index, BuildContext context) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ViewGalleryPage(
                  media: eventContext.media.allMedia,
                  initialIndex: index,
                  postId: eventContext.id,
                )));
  }

  Future<EventMedia> _fetchMedia() {
    final EventSupplementalDBManager manager = EventSupplementalDBManager(eventContext.id);
    return manager.fetchMedia();
  }
}
