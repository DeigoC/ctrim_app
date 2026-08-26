import 'dart:io' show File;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'add_media_test_states.dart';

class AddMediaVideoPlayerTest extends StatelessWidget {
  const AddMediaVideoPlayerTest({
    super.key,
    required this.canSave,
    required this.getSrc,
    required this.getInputUrl,
    required this.maxVideoSizeMB,
    required this.fetchFile,
    required this.mediaFileSizeBytes,
    required this.videoPlayerController,
    required this.isVideo,
    required this.onFetched,
    required this.onControllerCreated,
    required this.onVideoReady,
    required this.onVideoInitFailed,
    required this.onFileTooLarge,
    required this.onFetchFailed,
  });

  final bool canSave;
  final String Function() getSrc;
  final String Function() getInputUrl;
  final int maxVideoSizeMB;
  final Future<File?> Function() fetchFile;
  final int? Function() mediaFileSizeBytes;
  final VideoPlayerController? videoPlayerController;
  final bool isVideo;
  final void Function(File? tmpFile) onFetched;
  final void Function(VideoPlayerController controller) onControllerCreated;
  final VoidCallback onVideoReady;
  final VoidCallback onVideoInitFailed;
  final VoidCallback onFileTooLarge;
  final VoidCallback onFetchFailed;

  @override
  Widget build(BuildContext context) {
    if (canSave) {
      // On web, use network video player
      if (kIsWeb) {
        return AddMediaVideoPlayer(
          controller: videoPlayerController!,
          isVideo: isVideo,
        );
      }
      // On native, use cached file
      return AddMediaVideoPlayer(
        controller: videoPlayerController!,
        isVideo: isVideo,
      );
    }

    return FutureBuilder(
      future: fetchFile(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const AddMediaTestLoading(message: 'Checking video...');
        }

        final int? sizeBytes = mediaFileSizeBytes();
        if (snap.hasData || (kIsWeb && sizeBytes != null)) {
          onFetched(snap.data);

          final tmpFile = snap.data;
          final size = sizeBytes ?? (tmpFile?.lengthSync() ?? 0);
          final double sizeInMb = size / (1024 * 1024);

          if (sizeInMb <= maxVideoSizeMB || sizeBytes == 0) {
            debugPrint('video size is good: $sizeInMb MB');

            // Initialize video player
            final VideoPlayerController controller;
            if (kIsWeb) {
              controller =
                  VideoPlayerController.networkUrl(Uri.parse(getSrc()));
            } else {
              controller = VideoPlayerController.file(tmpFile!);
            }
            onControllerCreated(controller);

            WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
              controller.initialize().then((_) {
                onVideoReady();
              }).catchError((error) {
                debugPrint('Error initializing video player: $error');
                onVideoInitFailed();
              });
            });

            return const AddMediaTestLoading(
                message: 'Initializing video player...');
          } else {
            onFileTooLarge();
            return AddMediaTestFileSizeError(
              title: 'Video too large: ${sizeInMb.toStringAsFixed(1)} MB',
              subtitle:
                  'Maximum size is $maxVideoSizeMB MB. Please compress the video.',
              url: 'https://www.freeconvert.com/video-compressor',
              buttonText: 'Compress Video Online',
            );
          }
        }

        if (snap.hasError) {
          onFetchFailed();
          debugPrint('Error fetching video: ${snap.error}');
          return AddMediaTestError(
            message: 'Failed to load video: ${snap.error}',
            src: getSrc(),
            inputUrl: getInputUrl(),
          );
        }

        return const AddMediaTestLoading(message: 'Preparing...');
      },
    );
  }
}

class AddMediaVideoPlayer extends StatelessWidget {
  const AddMediaVideoPlayer({
    super.key,
    required this.controller,
    required this.isVideo,
  });

  final VideoPlayerController controller;
  final bool isVideo;

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const AddMediaTestLoading(message: 'Initializing video...');
    }

    debugPrint('Video player initialized!');
    controller.play();
    controller.setLooping(true);

    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.black,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
            ),
          ),
        ),
        if (isVideo) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    size: 16, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Video is ready! You can add a thumbnail URL above for better preview.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
