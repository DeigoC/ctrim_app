import 'package:flutter/material.dart';
import '../../models/event/event_head.dart';
import '../../pages/events/view_event_page.dart';
import '../../pages/view_gallery_page.dart';
import '../media/image_media_slot.dart';
import '../media/video_media_slot.dart';

class PostHead extends StatelessWidget {
  const PostHead({super.key, required this.thisHead});
  final EventHead thisHead;
  static const double _titleFontSize = 24, _subtitleFontSize = 16;

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [
      _buildTitle(),
      const SizedBox(
        height: 8,
      ),
      _buildSubtitle(),
      const SizedBox(
        height: 8,
      ),
      const Divider(),
    ];

    if (thisHead.media.isNotEmpty) {
      children.insert(0, _buildMediaSection(context));
    }

    return InkWell(
      onTap: () => _onHeadTap(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }

  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Text(
        thisHead.title,
        style: const TextStyle(fontSize: _titleFontSize),
      ),
    );
  }

  Widget _buildSubtitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Text(thisHead.subtitle,
          style: const TextStyle(
            fontSize: _subtitleFontSize,
          )),
    );
  }

  Widget _buildMediaSection(BuildContext context) {
    final List<Widget> children = [_buildMediaSlot(thisHead.media.first, 0, context)];

    if (thisHead.media.length == 2) {
      children.addAll([
        const SizedBox(
          width: 2,
        ),
        _buildMediaSlot(thisHead.media[1], 1, context)
      ]);
    } else if (thisHead.media.length == 3) {
      children.addAll([
        const SizedBox(
          width: 2,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildMediaSlot(thisHead.media[1], 1, context),
              const SizedBox(
                height: 2,
              ),
              _buildMediaSlot(thisHead.media[2], 2, context),
            ],
          ),
        )
      ]);
    } else if (thisHead.media.length == 4) {
      children[0] = Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildMediaSlot(thisHead.media[0], 0, context),
            const SizedBox(
              height: 2,
            ),
            _buildMediaSlot(thisHead.media[2], 2, context),
          ],
        ),
      );
      children.addAll([
        const SizedBox(
          width: 2,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildMediaSlot(thisHead.media[1], 1, context),
              const SizedBox(
                height: 2,
              ),
              _buildMediaSlot(thisHead.media[3], 3, context),
            ],
          ),
        )
      ]);
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }

  Widget _buildMediaSlot(Map<String, String> entry, int index, BuildContext context) {
    return entry['type']!.compareTo('img') == 0
        ? Expanded(child: ImageMediaSlot(mediaEntry: entry, onTap: () => _onMediaTap(index, context)))
        : Expanded(child: VideoMediaSlot(mediaEntry: entry, onTap: () => _onMediaTap(index, context)));
  }

  // * Logic

  void _onHeadTap(BuildContext context) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ViewEventPage(
                  eventHead: thisHead,
                  viewingChild: false,
                )));
  }

  void _onMediaTap(int index, BuildContext context) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ViewGalleryPage(
                  media: thisHead.media,
                  initialIndex: index,
                  postId: thisHead.id,
                )));
  }
}
