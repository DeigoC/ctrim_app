import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/event/event_head.dart';
import '../../pages/events/view_event_page.dart';
import '../../pages/view_gallery_page.dart';
import '../media/image_media_slot.dart';
import '../media/video_media_slot.dart';

class PostHead extends StatelessWidget {
  const PostHead(
      {super.key,
      required this.thisHead,
      this.viewingChild = false,
      this.childToParent = false,
      required this.updatePost});
  final EventHead thisHead;
  final bool viewingChild, childToParent;
  final Function() updatePost;
  static const double _titleFontSize = 24, _subtitleFontSize = 16;
  static final DateFormat _eventDateFormat = DateFormat('d MMM, HH:mm');

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [
      _buildTitle(),
      // const SizedBox(height: 2),
      _buildMetaData(),
      const SizedBox(height: 16),
      _buildSubtitle(),
      const SizedBox(height: 8)
    ];

    if (thisHead.media.isNotEmpty) {
      children.insert(0, _buildMediaSection(context));
    } else {
      children.insert(0, const SizedBox(height: 8));
    }

    return InkWell(
        onTap: () => _onHeadTap(context),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: children));
  }

  Widget _buildTitle() {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Text(thisHead.title, style: const TextStyle(fontSize: _titleFontSize)));
  }

  Widget _buildMetaData() {
    // final String timeAgo =
    final String finalStr = thisHead.eventDate != null
        ? 'On ${_eventDateFormat.format(thisHead.eventDate!)} • Edit ${timeAgo(thisHead.recentDate)}'
        : 'Edit ${timeAgo(thisHead.recentDate)}';

    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Text(finalStr, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)));
  }

  Widget _buildSubtitle() {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Text(thisHead.subtitle, style: const TextStyle(fontSize: _subtitleFontSize)));
  }

  Widget _buildMediaSection(BuildContext context) {
    final List<Widget> children = [_buildMediaSlot(thisHead.media.first, 0, context)];

    if (thisHead.media.length == 2) {
      children.addAll([const SizedBox(width: 2), _buildMediaSlot(thisHead.media[1], 1, context)]);
    } else if (thisHead.media.length == 3) {
      children.addAll([
        const SizedBox(width: 2),
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _buildMediaSlot(thisHead.media[1], 1, context),
          const SizedBox(height: 2),
          _buildMediaSlot(thisHead.media[2], 2, context),
        ]))
      ]);
    } else if (thisHead.media.length == 4) {
      children[0] = Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _buildMediaSlot(thisHead.media[0], 0, context),
        const SizedBox(height: 2),
        _buildMediaSlot(thisHead.media[2], 2, context),
      ]));
      children.addAll([
        const SizedBox(width: 2),
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _buildMediaSlot(thisHead.media[1], 1, context),
          const SizedBox(height: 2),
          _buildMediaSlot(thisHead.media[3], 3, context),
        ]))
      ]);
    }

    return Padding(
        padding: const EdgeInsets.all(8.0),
        child: AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: children))));
  }

  Widget _buildMediaSlot(Map<String, String> entry, int index, BuildContext context) {
    return entry['type']!.compareTo('img') == 0
        ? Expanded(
            child: ImageMediaSlot(
            mediaEntry: entry,
            onTap: () => _onMediaTap(index, context),
            postID: thisHead.id,
          ))
        : Expanded(
            child: VideoMediaSlot(mediaEntry: entry, postId: thisHead.id, onTap: () => _onMediaTap(index, context)));
  }

  // * Logic

  void _onHeadTap(BuildContext context) {
    if (childToParent) {
      Navigator.of(context).pop();
    } else {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ViewEventPage(
                    eventHead: thisHead,
                    viewingChild: viewingChild,
                  ))).then((_) => updatePost());
    }
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

  String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 5) {
      return "a few seconds ago";
    } else if (difference.inMinutes < 1) {
      return "a few minutes ago";
    } else if (difference.inHours < 1) {
      final minutes = difference.inMinutes;
      return "$minutes ${(minutes == 1) ? 'minute' : 'minutes'} ago";
    } else if (difference.inDays < 1) {
      final hours = difference.inHours;
      return "$hours ${(hours == 1) ? 'hour' : 'hours'} ago";
    } else {
      final days = difference.inDays;
      return "$days ${(days == 1) ? 'day' : 'days'} ago";
    }
  }
}
