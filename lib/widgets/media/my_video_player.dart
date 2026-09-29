import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../src/localization/app_localizations.dart';
import '../../utility/cache/local_data_manager.dart';
import '../../utility/gallery_viewer.dart';

class MyVideoPlayer extends StatefulWidget {
  const MyVideoPlayer({
    super.key,
    required this.src,
    required this.postID,
    required this.videoPlayerController,
    required this.isActive,
  });

  final String src;
  final String postID;
  final VideoPlayerController videoPlayerController;

  /// The page currently on screen. Neighbours load without starting playback.
  final bool isActive;

  @override
  State<MyVideoPlayer> createState() => _MyVideoPlayerState();
}

class _MyVideoPlayerState extends State<MyVideoPlayer> {
  late final Future<Uint8List?> _thumbnailFuture;
  bool _failed = false;
  bool _looping = false;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _thumbnailFuture = _readThumbnail();
    widget.videoPlayerController.addListener(_onTick);
    _start();
  }

  @override
  void didUpdateWidget(covariant MyVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoPlayerController != widget.videoPlayerController) {
      oldWidget.videoPlayerController.removeListener(_onTick);
      widget.videoPlayerController.addListener(_onTick);
      _failed = false;
      _looping = false;
      _start();
    } else if (oldWidget.isActive != widget.isActive) {
      _syncPlayback();
    }
  }

  @override
  void dispose() {
    widget.videoPlayerController.removeListener(_onTick);
    final value = widget.videoPlayerController.value;
    if (value.isInitialized && value.isPlaying) {
      widget.videoPlayerController.pause();
    }
    super.dispose();
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  Future<void> _start() async {
    final generation = ++_loadGeneration;
    final controller = widget.videoPlayerController;
    try {
      if (!controller.value.isInitialized) {
        await controller.initialize();
      }
      if (!mounted || generation != _loadGeneration) return;
      await controller.setLooping(_looping);
      if (!mounted || generation != _loadGeneration) return;
      if (widget.isActive && !controller.value.isPlaying) {
        await controller.play();
        if (!mounted || generation != _loadGeneration) return;
        if (!widget.isActive) await controller.pause();
      }
      if (mounted && generation == _loadGeneration)
        setState(() => _failed = false);
    } catch (error) {
      debugPrint('Video viewer failed to start ${widget.src}: $error');
      if (!mounted || generation != _loadGeneration) return;
      setState(() => _failed = true);
    }
  }

  void _syncPlayback() {
    final controller = widget.videoPlayerController;
    if (!controller.value.isInitialized || _failed) return;
    if (widget.isActive) {
      if (!controller.value.isPlaying) controller.play();
    } else if (controller.value.isPlaying) {
      controller.pause();
    }
  }

  void _togglePlay() {
    final controller = widget.videoPlayerController;
    if (!controller.value.isInitialized) return;
    if (controller.value.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }
  }

  void _toggleLoop() {
    final next = !_looping;
    setState(() => _looping = next);
    widget.videoPlayerController.setLooping(next);
  }

  Future<Uint8List?> _readThumbnail() {
    final localDataManager = LocalDataManager();
    final sanitisedKey = widget.src.replaceAll(RegExp(r'[^\w]'), '');
    return localDataManager.readVideoThumbnail(widget.postID, sanitisedKey);
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return _Failure(onRetry: _start);

    final value = widget.videoPlayerController.value;
    if (!value.isInitialized) return _buildLoading();

    final ratio = value.aspectRatio;
    final aspect = ratio.isNaN || ratio <= 0 ? 16 / 9 : ratio;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: AspectRatio(
            aspectRatio: aspect,
            child: Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(widget.videoPlayerController),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    tooltip:
                        value.isPlaying ? l10n.galleryPause : l10n.galleryPlay,
                    onPressed: _togglePlay,
                    icon: Icon(
                      value.isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 36,
                      color: Colors.white,
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.65),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 24, 4, 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          VideoProgressIndicator(
                            widget.videoPlayerController,
                            allowScrubbing: true,
                            colors: const VideoProgressColors(
                              playedColor: Colors.white,
                              bufferedColor: Colors.white38,
                              backgroundColor: Colors.white24,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                GalleryViewer.formatPlaybackTime(
                                    value.position),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                              const Spacer(),
                              Text(
                                GalleryViewer.formatPlaybackTime(
                                    value.duration),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                              IconButton(
                                tooltip: l10n.galleryLoop,
                                visualDensity: VisualDensity.compact,
                                onPressed: _toggleLoop,
                                icon: Icon(
                                  Icons.repeat,
                                  color:
                                      _looping ? Colors.white : Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return FutureBuilder<Uint8List?>(
      future: _thumbnailFuture,
      builder: (context, snapshot) {
        return Stack(
          alignment: Alignment.center,
          children: [
            if (snapshot.data != null)
              Positioned.fill(
                child: Hero(
                  tag: widget.postID + widget.src,
                  child: Image.memory(snapshot.data!, fit: BoxFit.contain),
                ),
              ),
            const CircularProgressIndicator(color: Colors.white),
          ],
        );
      },
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.videocam_off_outlined,
              size: 64, color: Colors.white70),
          const SizedBox(height: 16),
          Text(
            l10n.galleryVideoFailed,
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              onRetry();
            },
            child: Text(l10n.galleryRetry),
          ),
        ],
      ),
    );
  }
}
