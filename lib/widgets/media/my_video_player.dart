import 'package:flutter/material.dart';
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
            if (snap.connectionState == ConnectionState.done) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _videoController.play();
              });

              return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Flexible(
                    child: AspectRatio(
                        aspectRatio: _videoController.value.aspectRatio, child: VideoPlayer(_videoController))),
                IconButton(
                    onPressed: _onIconClick,
                    icon: AnimatedIcon(
                      icon: AnimatedIcons.pause_play,
                      progress: animation,
                      color: Colors.white,
                    )),
              ]);
            }
            return const Center(child: CircularProgressIndicator());
          }),
    );
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
}
