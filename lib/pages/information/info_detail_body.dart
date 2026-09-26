import 'package:flutter/material.dart';

import '../../models/info/info_parsing.dart';
import '../../utility/image_orientation.dart';
import '../../utility/info_detail_aside_layout.dart';
import '../../utility/responsive_layout.dart';
import '../../widgets/information/info_image_carousel.dart';
import '../../widgets/media/cached_image_widget.dart';
import '../../widgets/quill_editor_wrapper.dart';

/// Stacked detail: lead image, then the story in one scroll view.
class InfoDetailStackedBody extends StatelessWidget {
  const InfoDetailStackedBody({
    super.key,
    required this.imageUrls,
    required this.heroTag,
    required this.body,
    required this.header,
    required this.onRefresh,
    this.showCarouselWhenEmpty = true,
    this.carouselHeightFraction = 0.36,
    this.galleryImageUrls,
    this.aboveBody,
    this.bodyHeading,
    this.belowBody,
  });

  final List<String> imageUrls;
  final String heroTag;
  final List<dynamic> body;
  final Widget header;
  final Future<void> Function() onRefresh;
  final bool showCarouselWhenEmpty;
  final double carouselHeightFraction;
  final List<String>? galleryImageUrls;
  final Widget? aboveBody;
  final Widget? bodyHeading;
  final Widget? belowBody;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final double gutter =
        ResponsiveLayout.horizontalGutter(size.width, narrowPadding: 0);
    final bool isWide = ResponsiveLayout.isWideScreen(size.width);
    final double carouselHeight = size.height *
        (isWide ? carouselHeightFraction * 0.9 : carouselHeightFraction);
    final bool showCarousel = imageUrls.isNotEmpty || showCarouselWhenEmpty;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (showCarousel)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(gutter, isWide ? 8 : 0, gutter, 0),
                child: InfoImageCarousel(
                  imageUrls: imageUrls,
                  heroTag: heroTag,
                  landscapeHeight: carouselHeight,
                  borderRadius: isWide ? 16 : 0,
                ),
              ),
            ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(gutter + 16, 20, gutter + 16, 40),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isWide
                        ? ResponsiveLayout.chordMaxWidth
                        : double.infinity,
                  ),
                  child: _InfoDetailTextColumn(
                    header: header,
                    body: body,
                    galleryImages: _galleryImages(imageUrls, galleryImageUrls),
                    aboveBody: aboveBody,
                    bodyHeading: bodyHeading,
                    belowBody: belowBody,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Testimonial wide layout. Falls back to [InfoDetailStackedBody] for a
/// landscape photo or a narrow window.
class InfoDetailAsideHost extends StatefulWidget {
  const InfoDetailAsideHost({
    super.key,
    required this.imageUrls,
    required this.heroTag,
    required this.body,
    required this.header,
    required this.onRefresh,
    this.showCarouselWhenEmpty = true,
    this.carouselHeightFraction = 0.36,
    this.galleryImageUrls,
    this.aboveBody,
    this.bodyHeading,
    this.belowBody,
    this.knownLeadOrientation,
  });

  final List<String> imageUrls;
  final String heroTag;
  final List<dynamic> body;
  final Widget header;
  final Future<void> Function() onRefresh;
  final bool showCarouselWhenEmpty;
  final double carouselHeightFraction;
  final List<String>? galleryImageUrls;
  final Widget? aboveBody;
  final Widget? bodyHeading;
  final Widget? belowBody;

  /// Skips the image probe. Widget tests pass a portrait or landscape here.
  final ImageOrientation? knownLeadOrientation;

  @override
  State<InfoDetailAsideHost> createState() => _InfoDetailAsideHostState();
}

enum _LeadProbe { pending, known, failed }

class _InfoDetailAsideHostState extends State<InfoDetailAsideHost> {
  _LeadProbe _probe = _LeadProbe.pending;
  ImageOrientation? _orientation;
  int _generation = 0;
  Animation<double>? _routeAnimation;
  bool _arrived = false;

  @override
  void initState() {
    super.initState();
    final known = widget.knownLeadOrientation;
    if (known != null) {
      _probe = _LeadProbe.known;
      _orientation = known;
      _arrived = true;
      return;
    }
    _probeLead();
    WidgetsBinding.instance.addPostFrameCallback((_) => _listenForArrival());
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_onArrival);
    super.dispose();
  }

  void _listenForArrival() {
    if (!mounted) {
      return;
    }
    final animation = ModalRoute.of(context)?.animation;
    if (animation == null || animation.status == AnimationStatus.completed) {
      setState(() => _arrived = true);
      return;
    }
    _routeAnimation = animation;
    animation.addStatusListener(_onArrival);
  }

  void _onArrival(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) {
      return;
    }
    _routeAnimation?.removeStatusListener(_onArrival);
    _routeAnimation = null;
    setState(() => _arrived = true);
  }

  @override
  void didUpdateWidget(covariant InfoDetailAsideHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previous =
        oldWidget.imageUrls.isEmpty ? '' : oldWidget.imageUrls.first;
    final next = widget.imageUrls.isEmpty ? '' : widget.imageUrls.first;
    if (previous != next) {
      setState(() {
        _probe = _LeadProbe.pending;
        _orientation = null;
      });
      _probeLead();
    }
  }

  Future<void> _probeLead() async {
    final generation = ++_generation;
    final url = widget.imageUrls.isEmpty ? '' : widget.imageUrls.first;
    if (url.isEmpty) {
      if (!mounted || generation != _generation) {
        return;
      }
      setState(() {
        _probe = _LeadProbe.failed;
        _orientation = null;
      });
      return;
    }

    try {
      final bytes = await CachedImageLoader.fetchBytes(url);
      final size = await ImageOrientationHelper.decodeSize(bytes);
      if (!mounted || generation != _generation) {
        return;
      }
      if (size == null) {
        setState(() {
          _probe = _LeadProbe.failed;
          _orientation = null;
        });
        return;
      }
      setState(() {
        _probe = _LeadProbe.known;
        _orientation = ImageOrientationHelper.fromSize(size.width, size.height);
      });
    } catch (error) {
      debugPrint('InfoDetailAsideHost: lead probe failed ($error)');
      if (!mounted || generation != _generation) {
        return;
      }
      setState(() {
        _probe = _LeadProbe.failed;
        _orientation = null;
      });
    }
  }

  InfoDetailStackedBody _stacked() {
    return InfoDetailStackedBody(
      imageUrls: widget.imageUrls,
      heroTag: widget.heroTag,
      body: widget.body,
      header: widget.header,
      onRefresh: widget.onRefresh,
      showCarouselWhenEmpty: widget.showCarouselWhenEmpty,
      carouselHeightFraction: widget.carouselHeightFraction,
      galleryImageUrls: widget.galleryImageUrls,
      aboveBody: widget.aboveBody,
      bodyHeading: widget.bodyHeading,
      belowBody: widget.belowBody,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double windowWidth = MediaQuery.sizeOf(context).width;
        final double available =
            constraints.maxWidth - InfoDetailAsideLayout.outerPadding * 2;
        final bool wideWindow = ResponsiveLayout.isWideScreen(windowWidth);
        final bool measured = _probe != _LeadProbe.pending;
        // Keep the rail until the route animation finishes so a landscape
        // photo does not move the hero mid-flight.
        final bool holdForHero =
            measured && _orientation == ImageOrientation.landscape && !_arrived;
        final bool pin = wideWindow &&
            InfoDetailAsideLayout.pinLeadImage(
              enabled: true,
              availableWidth: available,
              hasLeadImage: widget.imageUrls.isNotEmpty,
              orientationKnown: holdForHero ? false : measured,
              leadOrientation: holdForHero ? null : _orientation,
            );
        if (!pin) {
          return _stacked();
        }

        final double railWidth = InfoDetailAsideLayout.railWidthFor(available);
        final double groupMax = railWidth +
            InfoDetailAsideLayout.columnGap +
            ResponsiveLayout.chordMaxWidth;

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            InfoDetailAsideLayout.outerPadding,
            8,
            InfoDetailAsideLayout.outerPadding,
            0,
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: groupMax),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: railWidth,
                    child: _AsideRail(
                      imageUrls: widget.imageUrls,
                      heroTag: widget.heroTag,
                      header: widget.header,
                    ),
                  ),
                  const SizedBox(width: InfoDetailAsideLayout.columnGap),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: widget.onRefresh,
                      child: CustomScrollView(
                        primary: false,
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.only(bottom: 40),
                            sliver: SliverToBoxAdapter(
                              child: _InfoDetailTextColumn(
                                header: widget.header,
                                body: widget.body,
                                galleryImages: _galleryImages(
                                  widget.imageUrls,
                                  widget.galleryImageUrls,
                                ),
                                aboveBody: widget.aboveBody,
                                bodyHeading: widget.bodyHeading,
                                belowBody: widget.belowBody,
                                showHeader: false,
                                showDivider: widget.aboveBody != null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AsideRail extends StatelessWidget {
  const _AsideRail({
    required this.imageUrls,
    required this.heroTag,
    required this.header,
  });

  final List<String> imageUrls;
  final String heroTag;
  final Widget header;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double photoMax =
            (constraints.maxHeight - 200).clamp(180.0, 640.0);
        return SingleChildScrollView(
          primary: false,
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InfoImageCarousel(
                frame: InfoImageCarouselFrame.rail,
                imageUrls: imageUrls,
                heroTag: heroTag,
                landscapeHeight: photoMax,
                railMaxHeight: photoMax,
                borderRadius: 16,
              ),
              const SizedBox(height: 16),
              header,
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

class _InfoDetailTextColumn extends StatelessWidget {
  const _InfoDetailTextColumn({
    required this.header,
    required this.body,
    required this.galleryImages,
    this.aboveBody,
    this.bodyHeading,
    this.belowBody,
    this.showHeader = true,
    this.showDivider = true,
  });

  final Widget header;
  final List<dynamic> body;
  final List<String> galleryImages;
  final Widget? aboveBody;
  final Widget? bodyHeading;
  final Widget? belowBody;
  final bool showHeader;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool hasBody = !InfoParsing.isEmptyBody(body);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHeader) header,
        if (aboveBody != null) ...[
          if (showHeader) const SizedBox(height: 16),
          aboveBody!,
        ],
        if (hasBody) ...[
          if (showDivider) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
          ],
          if (bodyHeading != null) ...[
            bodyHeading!,
            const SizedBox(height: 8),
          ],
          QuillViewerWidget(
            jsonContent: body,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          ),
        ],
        if (galleryImages.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Gallery',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...galleryImages.map(
            (imageUrl) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: AdaptiveInfoGalleryImage(imageUrl: imageUrl),
            ),
          ),
        ],
        if (belowBody != null) ...[
          const SizedBox(height: 20),
          belowBody!,
        ],
      ],
    );
  }
}

List<String> _galleryImages(
  final List<String> imageUrls,
  final List<String>? galleryImageUrls,
) {
  return galleryImageUrls ??
      (imageUrls.length > 1 ? imageUrls.skip(1).toList() : const <String>[]);
}
