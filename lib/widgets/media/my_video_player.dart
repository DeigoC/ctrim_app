import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

class MyVideoPlayer extends StatefulWidget {
  const MyVideoPlayer({super.key, required this.src});
  final String src;

  @override
  State<MyVideoPlayer> createState() => _MyVideoPlayerState();
}

class _MyVideoPlayerState extends State<MyVideoPlayer> with SingleTickerProviderStateMixin {
  late final VideoPlayerController _videoController;
  late final Future<void> _initialiseVideo;

  late AnimationController _videoPlaybackAnimationController;
  late Animation<double> animation;

  @override
  void initState() {
    _videoController = VideoPlayerController.network(widget.src);
    _initialiseVideo = _videoController.initialize();
    _videoController.setLooping(true);

    _videoPlaybackAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    animation = Tween<double>(begin: 0.0, end: 1.0).animate(_videoPlaybackAnimationController);
    super.initState();
  }

  @override
  void dispose() {
    _videoController.dispose();
    _videoPlaybackAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FutureBuilder(
          future: _initialiseVideo,
          builder: (_, snap) {
            List<Widget> children = [_buildThumbnailLoader()];

            if (snap.connectionState == ConnectionState.done) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _videoController.play();
              });

              children = [
                Flexible(
                    child: AspectRatio(
                        aspectRatio: _videoController.value.aspectRatio,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            VideoPlayer(_videoController),
                            IconButton(
                                onPressed: _onIconClick,
                                icon: AnimatedIcon(
                                  icon: AnimatedIcons.pause_play,
                                  progress: animation,
                                  color: Colors.white,
                                ))
                          ],
                        ))),
              ];
            } else if (snap.hasError) {
              children = [
                const Text(
                  'Something went wrong!',
                  textAlign: TextAlign.center,
                )
              ];
            }

            return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: children);
          }),
    );
  }

  Widget _buildThumbnailLoader() {
    return FutureBuilder(
        future: _attemptToGetExistingThumbnailFile(),
        builder: (_, snap) {
          Widget result = const Center(child: CircularProgressIndicator());

          if (snap.hasData) {
            final file = snap.data;
            result = Expanded(
              child: Stack(alignment: Alignment.center, children: [
                Positioned.fill(
                    child: Image.file(
                  file!,
                )),
                const CircularProgressIndicator()
              ]),
            );
          } else if (snap.hasError) {
            debugPrint('Something went wrong with attepmting to fetch the exisitng thumbnail: ${snap.error}');
            result = const Text(
              "Can't load video thumbnail",
              textAlign: TextAlign.center,
            );
          }

          return result;
        });
  }

  void _onIconClick() {
    if (_videoController.value.isPlaying) {
      _videoController.pause();
      _videoPlaybackAnimationController.forward();
    } else {
      // ? Idk about buffering
      _videoController.play();
      _videoPlaybackAnimationController.reverse();
    }
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
    final RegExp fileNameReg = RegExp(r'\/([^\/.]+)(?:\.[^\/.]+)?$');
    RegExpMatch? match = fileNameReg.firstMatch(widget.src);
    if (match != null) {
      final group = match.group(1)!;
      final result = group.replaceAll(r'%', '').replaceAll('?', '').replaceAll('=', '');
      return result; // for the google drive IDs
    }
    return null;
  }
}
