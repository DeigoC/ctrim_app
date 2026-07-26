import 'package:flutter/material.dart';

import '../../utility/image_orientation.dart';
import '../../utility/responsive_layout.dart';
import '../media/cached_image_widget.dart';

class InfoImageCarousel extends StatefulWidget {
  const InfoImageCarousel({
    super.key,
    required this.imageUrls,
    required this.heroTag,
    required this.landscapeHeight,
    this.borderRadius = 0,
    this.portraitMaxWidth = 420,
  });

  final double borderRadius;
  final double landscapeHeight;
  final double portraitMaxWidth;
  final String heroTag;
  final List<String> imageUrls;

  @override
  State<InfoImageCarousel> createState() => _InfoImageCarouselState();
}

class _InfoImageCarouselState extends State<InfoImageCarousel> {
  final PageController _pageController = PageController();
  final Map<String, Size> _intrinsicSizes = <String, Size>{};
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _probeAround(_currentIndex);
  }

  @override
  void didUpdateWidget(covariant InfoImageCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_listEquals(oldWidget.imageUrls, widget.imageUrls)) {
      _intrinsicSizes.clear();
      _currentIndex = 0;
      _probeAround(_currentIndex);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool _listEquals(final List<String> a, final List<String> b) {
    if (identical(a, b)) {
      return true;
    }
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }

  void _probeAround(final int index) {
    if (widget.imageUrls.isEmpty) {
      return;
    }
    _probeUrl(widget.imageUrls[index]);
    if (index + 1 < widget.imageUrls.length) {
      _probeUrl(widget.imageUrls[index + 1]);
    }
    if (index - 1 >= 0) {
      _probeUrl(widget.imageUrls[index - 1]);
    }
  }

  Future<void> _probeUrl(final String url) async {
    if (url.isEmpty || _intrinsicSizes.containsKey(url)) {
      return;
    }

    try {
      final bytes = await CachedImageLoader.fetchBytes(url);
      final size = await ImageOrientationHelper.decodeSize(bytes);
      if (!mounted || size == null) {
        return;
      }
      setState(() {
        _intrinsicSizes[url] = size;
      });
    } catch (error) {
      debugPrint('InfoImageCarousel: failed to probe $url ($error)');
    }
  }

  Size? get _currentIntrinsic {
    if (widget.imageUrls.isEmpty) {
      return null;
    }
    return _intrinsicSizes[widget.imageUrls[_currentIndex]];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screen = MediaQuery.sizeOf(context);
    final bool isWide = ResponsiveLayout.isWideScreen(screen.width);
    final double availableWidth = screen.width -
        (isWide ? ResponsiveLayout.horizontalGutter(screen.width) * 2 : 0);

    if (widget.imageUrls.isEmpty) {
      return Container(
        height: widget.landscapeHeight * 0.5,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.photo_library_outlined,
          size: 48,
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }

    final Size? intrinsic = _currentIntrinsic;
    final ImageOrientation orientation = intrinsic == null
        ? ImageOrientation.landscape
        : ImageOrientationHelper.fromSize(intrinsic.width, intrinsic.height);
    // Anything not clearly landscape (portraits + square headshots) gets a
    // centered natural frame instead of a full-bleed wide banner.
    final bool useNaturalFrame = orientation != ImageOrientation.landscape;

    final double maxHeight = (screen.height * (useNaturalFrame ? 0.58 : 0.42))
        .clamp(220.0, widget.landscapeHeight * (useNaturalFrame ? 1.65 : 1.0));
    final double maxWidth = useNaturalFrame
        ? widget.portraitMaxWidth
            .clamp(240.0, availableWidth * (isWide ? 0.38 : 0.78))
        : availableWidth;

    final Size displaySize = intrinsic == null
        ? Size(availableWidth, widget.landscapeHeight)
        : ImageOrientationHelper.fitWithin(
            intrinsic: intrinsic,
            maxWidth: maxWidth,
            maxHeight: maxHeight,
          );

    final BoxFit fit = useNaturalFrame ? BoxFit.contain : BoxFit.cover;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          width: double.infinity,
          height: displaySize.height,
          alignment: Alignment.center,
          color: useNaturalFrame ? colorScheme.surfaceContainerLow : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            width: displaySize.width,
            height: displaySize.height,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                useNaturalFrame || isWide ? 16 : widget.borderRadius,
              ),
              child: ColoredBox(
                color: colorScheme.surfaceContainerHighest,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      itemCount: widget.imageUrls.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentIndex = index;
                        });
                        _probeAround(index);
                      },
                      itemBuilder: (context, index) {
                        final url = widget.imageUrls[index];
                        final pageSize = _intrinsicSizes[url];
                        final pageNatural = pageSize != null &&
                            ImageOrientationHelper.fromSize(
                                  pageSize.width,
                                  pageSize.height,
                                ) !=
                                ImageOrientation.landscape;

                        return CachedImageWidget(
                          imageUrl: url,
                          fit: pageNatural ? BoxFit.contain : fit,
                          heroTag: index == 0 ? widget.heroTag : null,
                        );
                      },
                    ),
                    if (widget.imageUrls.length > 1)
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${_currentIndex + 1}/${widget.imageUrls.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (widget.imageUrls.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List<Widget>.generate(widget.imageUrls.length, (index) {
              final isActive = index == _currentIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: isActive ? 20 : 8,
                decoration: BoxDecoration(
                  color: isActive
                      ? colorScheme.primary
                      : colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

/// Gallery tile that uses the image's intrinsic aspect ratio.
class AdaptiveInfoGalleryImage extends StatefulWidget {
  const AdaptiveInfoGalleryImage({super.key, required this.imageUrl});

  final String imageUrl;

  @override
  State<AdaptiveInfoGalleryImage> createState() =>
      _AdaptiveInfoGalleryImageState();
}

class _AdaptiveInfoGalleryImageState extends State<AdaptiveInfoGalleryImage> {
  Size? _intrinsic;

  @override
  void initState() {
    super.initState();
    _probe();
  }

  @override
  void didUpdateWidget(covariant AdaptiveInfoGalleryImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _intrinsic = null;
      _probe();
    }
  }

  Future<void> _probe() async {
    try {
      final bytes = await CachedImageLoader.fetchBytes(widget.imageUrl);
      final size = await ImageOrientationHelper.decodeSize(bytes);
      if (!mounted || size == null) {
        return;
      }
      setState(() {
        _intrinsic = size;
      });
    } catch (error) {
      debugPrint('AdaptiveInfoGalleryImage: probe failed ($error)');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final intrinsic = _intrinsic;
    final bool naturalFrame = intrinsic != null &&
        ImageOrientationHelper.fromSize(intrinsic.width, intrinsic.height) !=
            ImageOrientation.landscape;
    final double ratio =
        intrinsic == null ? 16 / 9 : intrinsic.width / intrinsic.height;

    final image = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: ratio,
        child: ColoredBox(
          color: colorScheme.surfaceContainerHighest,
          child: CachedImageWidget(
            imageUrl: widget.imageUrl,
            fit: naturalFrame ? BoxFit.contain : BoxFit.cover,
          ),
        ),
      ),
    );

    if (!naturalFrame) {
      return image;
    }

    return Align(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: image,
      ),
    );
  }
}
