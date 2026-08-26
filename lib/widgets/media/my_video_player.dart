import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../utility/cache/local_data_manager.dart';

class MyVideoPlayer extends StatefulWidget {
  const MyVideoPlayer(
      {super.key,
      required this.src,
      required this.postID,
      required this.onLockTap,
      required this.videoPlayerController,
      required this.showControls});
  final String src, postID;
  final bool showControls;
  final Function onLockTap;
  final VideoPlayerController videoPlayerController;

  @override
  State<MyVideoPlayer> createState() => _MyVideoPlayerState();
}

class _MyVideoPlayerState extends State<MyVideoPlayer> with SingleTickerProviderStateMixin {
  late AnimationController _videoPlaybackAnimationController;
  late Animation<double> animation;

  @override
  void initState() {
    if (widget.videoPlayerController.value.isInitialized &&
        !widget.videoPlayerController.value.isPlaying &&
        widget.videoPlayerController.value.position != Duration.zero) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _videoPlaybackAnimationController.forward();
      });
    }

    widget.videoPlayerController.setLooping(true);

    _videoPlaybackAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    animation = Tween<double>(begin: 0.0, end: 1.0).animate(_videoPlaybackAnimationController);
    super.initState();
  }

  @override
  void dispose() {
    // widget.videoPlayerController.pause();
    // widget.videoPlayerController.seekTo(Duration.zero);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.videoPlayerController.value.isInitialized ? _buildVideoPlayer() : _buildVideoInitialiser();
  }

  Widget _buildVideoInitialiser() {
    debugPrint('initialising the video for: ${widget.src}');
    return FutureBuilder(
        future: widget.videoPlayerController.initialize(),
        builder: (_, snap) {
          Widget result = _buildThumbnailLoader();

          if (snap.connectionState == ConnectionState.done) {
            result = _buildVideoPlayer();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              widget.videoPlayerController.play();
            });
          } else if (snap.hasError) {
            debugPrint('something went wrong with video initialiser: ${snap.error}');
            result = const Center(child: Text('Something went wrong'));
          }

          return result;
        });
  }

  Widget _buildVideoPlayer() {
    final List<Widget> children = [
      Flexible(
        child: AspectRatio(
            aspectRatio: widget.videoPlayerController.value.aspectRatio,
            child: Stack(alignment: Alignment.center, children: [
              VideoPlayer(widget.videoPlayerController),
              Positioned(
                  bottom: 0,
                  width: MediaQuery.of(context).size.width,
                  child: VideoProgressIndicator(widget.videoPlayerController, allowScrubbing: true)),
              widget.showControls
                  ? IconButton(
                      onPressed: _onIconClick,
                      icon: AnimatedIcon(
                          icon: AnimatedIcons.pause_play, progress: animation, size: 32, color: Colors.white))
                  : Container()
            ])),
      )
    ];

    return InkWell(
      onTap: () {
        widget.onLockTap();
      },
      splashColor: Colors.transparent,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: children),
    );
  }

  Widget _buildThumbnailLoader() {
    return FutureBuilder<Uint8List?>(
      future: _getCachedThumbnail(),
      builder: (context, snapshot) {
        final List<Widget> children = [const CircularProgressIndicator()];

        if (snapshot.hasData && snapshot.data != null) {
          children.insert(
            0,
            Positioned.fill(
              child: Hero(
                tag: widget.postID + widget.src,
                child: Image.memory(
                  snapshot.data!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [Expanded(child: Stack(alignment: Alignment.center, children: children))],
        );
      },
    );
  }

  Future<Uint8List?> _getCachedThumbnail() async {
    final localDataManager = LocalDataManager();
    final sanitisedKey = widget.src.replaceAll(RegExp(r'[^\w]'), '');
    return await localDataManager.readVideoThumbnail(widget.postID, sanitisedKey);
  }

  void _onIconClick() {
    if (widget.videoPlayerController.value.isPlaying) {
      widget.videoPlayerController.pause();
      _videoPlaybackAnimationController.forward();
    } else {
      // ? Idk about buffering
      widget.videoPlayerController.play();
      _videoPlaybackAnimationController.reverse();
    }
  }
}
