import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../utility/app_context.dart';

class MyVideoPlayer extends StatefulWidget {
  const MyVideoPlayer({super.key, required this.src, required this.postID});
  final String src, postID;

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
    final String cacheDir = Provider.of<AppContext>(context, listen: false).appDir;
    final sanitisedFilePath = widget.src.replaceAll(RegExp(r'[^\w]'), '');
    final fullPath = '$cacheDir/posts/${widget.postID}/$sanitisedFilePath.webp';
    final file = File(fullPath);

    final List<Widget> children = [const CircularProgressIndicator()];
    if (file.existsSync()) {
      children.insert(0, Positioned.fill(child: Hero(tag: widget.postID + widget.src, child: Image.file(file))));
    }

    return Expanded(child: Stack(alignment: Alignment.center, children: children));
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
