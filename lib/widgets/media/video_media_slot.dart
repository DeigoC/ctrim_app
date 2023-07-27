import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class VideoMediaSlot extends StatefulWidget {
  const VideoMediaSlot({super.key, required this.mediaEntry, required this.onTap});
  final Map<String, String> mediaEntry;
  final Function()? onTap;

  @override
  State<VideoMediaSlot> createState() => _VideoMediaSlotState();
}

class _VideoMediaSlotState extends State<VideoMediaSlot> {
  static final RegExp _fileNameReg = RegExp(r'\/([^\/.]+)(?:\.[^\/.]+)?$');
  File? _thisThumbnail;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InkWell(onTap: widget.onTap, child: const Text('This is a video')),
    );
    // return FutureBuilder(
    //     future: _attemptToGetExistingThumbnailFile(),
    //     builder: (_, snap) {
    //       Widget result = const Center(
    //         child: CircularProgressIndicator(),
    //       );

    //       if (snap.hasData) {
    //         _thisThumbnail = snap.data;
    //         result = _buildExistingThumbnail();
    //       } else if (!snap.hasData) {
    //         result = _buildThumbnailFB();
    //       } else if (snap.hasError) {
    //         debugPrint('Something went wrong with attepmting to fetch the exisitng thumbnail: ${snap.error}');
    //         result = const Center(
    //           child: Text('Something went wrong'),
    //         );
    //       }

    //       return result;
    //     });
  }

  Widget _buildThumbnailFB() {
    return FutureBuilder(
        future: _createThumbnail(),
        builder: (_, snap) {
          Widget result = const Center(
            child: CircularProgressIndicator(),
          );

          if (snap.hasData) {
            _thisThumbnail = File(snap.data!);
            debugPrint(_thisThumbnail!.path);
            result = _buildExistingThumbnail();
          } else if (snap.hasError) {
            result = const Center(
              child: Text('Something went wrong'),
            );
            debugPrint('Something with the Video Media Slot: ${snap.error}');
          }

          return result;
        });
  }

  Widget _buildExistingThumbnail() {
    return InkWell(
      onTap: widget.onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Image.file(
              _thisThumbnail!,
              fit: BoxFit.cover,
            ),
          ),
          const Icon(
            Icons.play_circle,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  // * Logic
  Future<String?> _createThumbnail() async {
    String path = (await getTemporaryDirectory()).path;

    String? title = _attemptToGetImageID();
    if (title != null) {
      path += '/$title.webp';
    }

    final String? result = await VideoThumbnail.thumbnailFile(
        video: widget.mediaEntry['src']!, thumbnailPath: path, imageFormat: ImageFormat.WEBP);

    return result;
  }

  Future<File?> _attemptToGetExistingThumbnailFile() async {
    String? title = _attemptToGetImageID();
    if (title != null) {
      final file = File('${(await getTemporaryDirectory()).path}/$title.webp');

      if (await file.exists()) {
        return file;
      }
    }
    return null;
  }

  String? _attemptToGetImageID() {
    RegExpMatch? match = _fileNameReg.firstMatch(widget.mediaEntry['src']!);
    if (match != null) {
      final group = match.group(1)!;
      final result = group.replaceAll(r'%', '').replaceAll('?', '').replaceAll('=', '');
      return result; // for the google drive IDs
    }
    return null;
  }
}
