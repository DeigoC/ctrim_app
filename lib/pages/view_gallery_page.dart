import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../src/localization/app_localizations.dart';
import '../utility/app_context.dart';
import '../utility/gallery_viewer.dart';
import '../widgets/media/my_photo_viewer.dart';
import '../widgets/media/my_video_player.dart';

class ViewGalleryPage extends StatefulWidget {
  const ViewGalleryPage({
    super.key,
    required this.media,
    required this.initialIndex,
    required this.postId,
    this.useHero = true,
    this.logPostView = true,
  });

  final List<Map<String, dynamic>> media;
  final int initialIndex;
  final String postId;

  /// Post media thumbnails share a [Hero] tag (`postId + src`). Other screens
  /// set `heroTag` on each entry. Pass false when the tapped image has no
  /// matching source hero (the cell group cover).
  final bool useHero;

  /// Post opens record a gallery view. Profile, cell group, and team tag
  /// opens pass false so they are not logged as a post.
  final bool logPostView;

  @override
  State<ViewGalleryPage> createState() => _ViewGalleryPageState();
}

class _ViewGalleryPageState extends State<ViewGalleryPage> {
  late final PageController _pageController;
  late int _index;
  bool _popped = false;

  final Map<String, VideoPlayerController> _videoControllers = {};
  final Map<int, bool> _photoFit = {};

  @override
  void initState() {
    super.initState();
    final last = widget.media.isEmpty ? 0 : widget.media.length - 1;
    _index = widget.initialIndex.clamp(0, last).toInt();
    _pageController =
        PageController(initialPage: widget.media.isEmpty ? 0 : _index);

    for (final entry in widget.media) {
      final src = entry['src'];
      if (entry['type'] == 'vid' && src is String && src.isNotEmpty) {
        _videoControllers[src] =
            VideoPlayerController.networkUrl(Uri.parse(src));
      }
    }

    if (widget.logPostView) {
      Provider.of<AppContext>(context, listen: false)
          .analytics
          .logPostGallery(widget.postId);
    }
  }

  @override
  void dispose() {
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  void _popOnce() {
    if (_popped || !mounted) return;
    _popped = true;
    Navigator.of(context).pop();
  }

  void _onPhotoFitChanged(int index, bool fit) {
    if ((_photoFit[index] ?? true) == fit) return;
    setState(() => _photoFit[index] = fit);
  }

  bool _allowsSwipe(int index) {
    final entry = widget.media[index];
    return GalleryViewer.allowsPagingAndDismiss(
      isPhoto: entry['type'] == 'img',
      photoIsFit: _photoFit[index] ?? true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (widget.media.isEmpty)
            Center(
              child: Text(
                l10n.galleryMediaUnsupported,
                style: const TextStyle(color: Colors.white),
              ),
            )
          else
            PhotoViewGestureDetectorScope(
              axis: Axis.horizontal,
              child: SafeArea(
                top: false,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: widget.media.length,
                  physics: _allowsSwipe(_index)
                      ? null
                      : const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) => setState(() => _index = index),
                  itemBuilder: (context, index) {
                    return _GalleryDragDismiss(
                      enabled: _allowsSwipe(index),
                      onDismissed: _popOnce,
                      child: _buildMediaBody(index),
                    );
                  },
                ),
              ),
            ),
          _buildChrome(l10n),
        ],
      ),
    );
  }

  Widget _buildChrome(AppLocalizations l10n) {
    final title = widget.media.isEmpty ? '' : _titleAt(_index);
    return Align(
      alignment: Alignment.topCenter,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: kToolbarHeight,
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.35),
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    tooltip: l10n.galleryClose,
                    onPressed: _popOnce,
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                  Expanded(
                    child: IgnorePointer(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  if (widget.media.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: IgnorePointer(
                        child: Text(
                          l10n.galleryPosition(_index + 1, widget.media.length),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaBody(int index) {
    return SizedBox.expand(child: _buildMediaView(widget.media[index], index));
  }

  Widget _buildMediaView(Map<String, dynamic> entry, int index) {
    final src = entry['src'];
    if (src is! String || src.isEmpty) {
      return const _Unsupported();
    }

    if (entry['type'] == 'vid') {
      final controller = _videoControllers[src];
      if (controller == null) return const _Unsupported();
      return MyVideoPlayer(
        key: ValueKey('vid-$src'),
        src: src,
        postID: widget.postId,
        isActive: index == _index,
        videoPlayerController: controller,
      );
    }

    if (entry['type'] == 'img') {
      final explicit = entry['heroTag'];
      final heroTag = GalleryViewer.resolvedHeroTag(
        useHero: widget.useHero,
        explicitTag: explicit is String ? explicit : null,
        fallbackTag: widget.postId + src,
      );
      return MyPhotoViewer(
        key: ValueKey('img-$src'),
        src: src,
        postID: widget.postId,
        heroTag: heroTag,
        useHero: GalleryViewer.attachHero(
          useHero: widget.useHero,
          isCurrentPage: index == _index,
          heroTag: heroTag,
        ),
        onFitChanged: (fit) => _onPhotoFitChanged(index, fit),
      );
    }

    return const _Unsupported();
  }

  String _titleAt(int index) {
    final title = widget.media[index]['title'];
    if (title is! String) return '';
    return title;
  }
}

class _Unsupported extends StatelessWidget {
  const _Unsupported();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        AppLocalizations.of(context)!.galleryMediaUnsupported,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}

class _GalleryDragDismiss extends StatefulWidget {
  const _GalleryDragDismiss({
    required this.enabled,
    required this.onDismissed,
    required this.child,
  });

  final bool enabled;
  final VoidCallback onDismissed;
  final Widget child;

  @override
  State<_GalleryDragDismiss> createState() => _GalleryDragDismissState();
}

class _GalleryDragDismissState extends State<_GalleryDragDismiss> {
  double _drag = 0;
  bool _dragging = false;

  @override
  void didUpdateWidget(covariant _GalleryDragDismiss oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && (_drag != 0 || _dragging)) {
      _drag = 0;
      _dragging = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final duration =
        _dragging ? Duration.zero : const Duration(milliseconds: 180);
    final media = AnimatedContainer(
      duration: duration,
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(0, _drag, 0),
      child: AnimatedOpacity(
        duration: duration,
        opacity: (1 - (_drag.abs() / 500)).clamp(0.45, 1.0),
        child: widget.child,
      ),
    );

    if (!widget.enabled) return media;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: (_) => setState(() => _dragging = true),
      onVerticalDragUpdate: (details) =>
          setState(() => _drag += details.delta.dy),
      onVerticalDragCancel: () => setState(() {
        _dragging = false;
        _drag = 0;
      }),
      onVerticalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (GalleryViewer.shouldDismissDrag(
            offset: _drag, velocity: velocity)) {
          widget.onDismissed();
          return;
        }
        setState(() {
          _dragging = false;
          _drag = 0;
        });
      },
      child: media,
    );
  }
}
