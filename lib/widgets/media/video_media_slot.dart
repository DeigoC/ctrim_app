import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class VideoMediaSlot extends StatefulWidget {
  const VideoMediaSlot({super.key, required this.mediaEntry, required this.onTap, required this.postId});
  final String postId;
  final Map<String, String> mediaEntry;
  final Function()? onTap;

  @override
  State<VideoMediaSlot> createState() => _VideoMediaSlotState();
}

class _VideoMediaSlotState extends State<VideoMediaSlot> {
  File? _thisThumbnail;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _attemptToGetExistingThumbnailFile(),
        builder: (_, snap) {
          Widget result = const Center(child: CircularProgressIndicator());

          if (snap.hasData) {
            _thisThumbnail = snap.data;
            result = _buildExistingThumbnail();
          } else if (!snap.hasData) {
            result = _buildThumbnailFB();
          } else if (snap.hasError) {
            debugPrint('Something went wrong with attepmting to fetch the exisitng thumbnail: ${snap.error}');
            result = const Center(child: Text("Can't load video thumbnail"));
          }

          return result;
        });
  }

  Widget _buildThumbnailFB() {
    return FutureBuilder(
        future: _createThumbnail(),
        builder: (_, snap) {
          Widget result = const Center(child: CircularProgressIndicator());

          if (snap.hasData) {
            _thisThumbnail = File(snap.data!);
            debugPrint('saving thumbnail to ${_thisThumbnail!.path}');
            result = _buildExistingThumbnail();
          } else if (snap.hasError) {
            result = const Center(child: Text("Can't load video"));
            debugPrint('Something with the Video Media Slot: ${snap.error}');
          }

          return result;
        });
  }

  Widget _buildExistingThumbnail() {
    return InkWell(
        onTap: widget.onTap,
        child: Stack(alignment: Alignment.center, children: [
          Positioned.fill(child: Image.file(_thisThumbnail!, fit: BoxFit.cover)),
          const Icon(Icons.play_circle, color: Colors.white)
        ]));
  }

  // * Logic
  Future<String?> _createThumbnail() async {
    final String title = _removeSpecialCharacters(widget.mediaEntry['src']!);
    final String path = '${(await getApplicationDocumentsDirectory()).path}/posts/${widget.postId}/$title.webp';

    final String? result = await VideoThumbnail.thumbnailFile(
        video: widget.mediaEntry['src']!, thumbnailPath: path, imageFormat: ImageFormat.WEBP, quality: 5);

    return result;
  }

  Future<File?> _attemptToGetExistingThumbnailFile() async {
    final String title = _removeSpecialCharacters(widget.mediaEntry['src']!);
    final file = File('${(await getApplicationDocumentsDirectory()).path}/posts/${widget.postId}/$title.webp');

    if (await file.exists()) {
      return file;
    }
    debugPrint('thumbnail for $title does not exist!');
    return null;
  }

  String _removeSpecialCharacters(String webLink) {
    return webLink.replaceAll(RegExp(r'[^\w]'), '');
  }
}
