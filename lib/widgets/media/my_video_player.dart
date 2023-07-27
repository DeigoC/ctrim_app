import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class MyVideoPlayer extends StatefulWidget {
  const MyVideoPlayer({super.key, required this.src});
  final String src;

  @override
  State<MyVideoPlayer> createState() => _MyVideoPlayerState();
}

class _MyVideoPlayerState extends State<MyVideoPlayer> {
  late final VideoPlayerController _videoController;
  late final Future<void> _initialiseVideo;

  @override
  void initState() {
    _videoController = VideoPlayerController.network(widget.src);
    _initialiseVideo = _videoController.initialize();
    _videoController.setLooping(true);
    super.initState();
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_videoController.value.isInitialized){
      return SingleChildScrollView(
        child: Column(children: [
          AspectRatio(aspectRatio: _videoController.value.aspectRatio, child: VideoPlayer(_videoController)),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(
                onPressed: () {
                  _videoController.pause();
                },
                icon: const Icon(Icons.pause)),
            IconButton(
                onPressed: () {
                  _videoController.play();
                },
                icon: const Icon(Icons.play_arrow))
          ])
        ]),
      );
    }
    return FutureBuilder(
        future: _initialiseVideo,
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.done) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _videoController.play();
            });

            return SingleChildScrollView(
              child: Column(children: [
                AspectRatio(aspectRatio: _videoController.value.aspectRatio, child: VideoPlayer(_videoController)),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  IconButton(
                      onPressed: () {
                        _videoController.pause();
                      },
                      icon: const Icon(Icons.pause)),
                  IconButton(
                      onPressed: () {
                        _videoController.play();
                      },
                      icon: const Icon(Icons.play_arrow))
                ])
              ]),
            );
          }
          return const Center(child: CircularProgressIndicator());
        });
  }
}
