import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

import '../../src/localization/app_localizations.dart';
import '../../utility/cache/local_data_manager.dart';
import 'cached_image_widget.dart';

class MyPhotoViewer extends StatefulWidget {
  const MyPhotoViewer({
    super.key,
    required this.src,
    required this.postID,
    required this.onFitChanged,
    this.useHero = true,
    this.heroTag,
  });

  final String src;
  final String postID;
  final String? heroTag;

  /// True while the photo is fit to the screen. The gallery uses this to
  /// decide whether paging and swipe-to-close may take the gesture.
  final ValueChanged<bool> onFitChanged;

  /// When true, pairs with the thumbnail [Hero]. [heroTag] wins; otherwise
  /// the tag is `postID + src` (post media).
  final bool useHero;

  @override
  State<MyPhotoViewer> createState() => _MyPhotoViewerState();
}

class _MyPhotoViewerState extends State<MyPhotoViewer> {
  Uint8List? _bytes;
  bool _failed = false;
  bool _allowFitReports = false;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _bytes = CachedImageLoader.peekBytes(widget.src);
    if (_bytes == null) {
      _load();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _allowFitReports = true;
      if (!mounted) return;
      widget.onFitChanged(true);
    });
  }

  @override
  void didUpdateWidget(covariant MyPhotoViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.src != widget.src) {
      _bytes = CachedImageLoader.peekBytes(widget.src);
      _failed = false;
      if (_bytes == null) _load();
    }
  }

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    try {
      final bytes = await CachedImageLoader.fetchBytes(widget.src);
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _bytes = bytes;
        _failed = false;
      });
    } catch (error) {
      debugPrint('Photo viewer failed to load ${widget.src}: $error');
      if (!mounted || generation != _loadGeneration) return;
      setState(() => _failed = true);
    }
  }

  Future<void> _retry() async {
    CachedImageLoader.forgetBytes(widget.src);
    await LocalDataManager().deleteMediaImage(
      CachedImageLoader.cacheKeyFor(widget.src),
    );
    if (!mounted) return;
    setState(() {
      _bytes = null;
      _failed = false;
    });
    await _load();
  }

  void _onScaleState(PhotoViewScaleState state) {
    if (!_allowFitReports) return;
    widget.onFitChanged(state == PhotoViewScaleState.initial);
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return _Failure(onRetry: _retry);

    final bytes = _bytes;
    if (bytes == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return PhotoView(
      imageProvider: MemoryImage(bytes),
      backgroundDecoration: const BoxDecoration(color: Colors.black),
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 2.5,
      initialScale: PhotoViewComputedScale.contained,
      gaplessPlayback: true,
      scaleStateChangedCallback: _onScaleState,
      heroAttributes: widget.useHero
          ? PhotoViewHeroAttributes(
              tag: (widget.heroTag != null && widget.heroTag!.isNotEmpty)
                  ? widget.heroTag!
                  : widget.postID + widget.src,
            )
          : null,
      loadingBuilder: (context, event) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
      errorBuilder: (context, error, stackTrace) => _Failure(onRetry: _retry),
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
          const Icon(Icons.broken_image_outlined,
              size: 64, color: Colors.white70),
          const SizedBox(height: 16),
          Text(
            l10n.galleryImageFailed,
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
