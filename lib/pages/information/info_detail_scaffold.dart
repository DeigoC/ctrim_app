import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../utility/app_context.dart';
import '../../utility/refresh_cooldown.dart';
import '../../utility/responsive_layout.dart';
import '../../widgets/information/info_image_carousel.dart';
import '../../widgets/load_progress_body.dart';
import '../../widgets/quill_editor_wrapper.dart';

/// Shared detail layout for church / testimonial / CTRIM info pages.
class InfoDetailPageScaffold extends StatelessWidget {
  const InfoDetailPageScaffold({
    super.key,
    required this.title,
    required this.imageUrls,
    required this.heroTag,
    required this.body,
    required this.header,
    required this.onRefresh,
    this.onEdit,
    this.editTooltip = 'Edit',
    this.showCarouselWhenEmpty = true,
    this.carouselHeightFraction = 0.36,
    this.aboveBody,
  });

  final String title;
  final List<String> imageUrls;
  final String heroTag;
  final List<dynamic> body;
  final Widget header;
  final Future<void> Function() onRefresh;
  final VoidCallback? onEdit;
  final String editTooltip;
  final bool showCarouselWhenEmpty;
  final double carouselHeightFraction;
  final Widget? aboveBody;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.sizeOf(context);
    final double gutter =
        ResponsiveLayout.horizontalGutter(size.width, narrowPadding: 0);
    final bool isWide = ResponsiveLayout.isWideScreen(size.width);
    final double carouselHeight = size.height *
        (isWide ? carouselHeightFraction * 0.9 : carouselHeightFraction);
    final bool showCarousel = imageUrls.isNotEmpty || showCarouselWhenEmpty;
    final List<String> galleryImages =
        imageUrls.length > 1 ? imageUrls.skip(1).toList() : const <String>[];

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        actions: [
          if (onEdit != null)
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit),
              tooltip: editTooltip,
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (showCarousel)
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      EdgeInsets.fromLTRB(gutter, isWide ? 8 : 0, gutter, 0),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        header,
                        if (aboveBody != null) ...[
                          const SizedBox(height: 16),
                          aboveBody!,
                        ],
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),
                        QuillViewerWidget(
                          jsonContent: body,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 8),
                        ),
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
                              child:
                                  AdaptiveInfoGalleryImage(imageUrl: imageUrl),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stateful wrapper that loads one info document, logs analytics, and supports edit/refresh.
class InfoDetailLoader<T> extends StatefulWidget {
  const InfoDetailLoader({
    super.key,
    required this.load,
    required this.analyticsScreenName,
    required this.pageTitleFallback,
    required this.notFoundMessage,
    required this.openEditor,
    required this.buildScaffold,
    this.canEdit,
  });

  final Future<T?> Function({required bool forceRefresh}) load;
  final String Function(T info) analyticsScreenName;
  final String pageTitleFallback;
  final String notFoundMessage;
  final Future<bool> Function(BuildContext context, T info) openEditor;
  final bool Function(User user)? canEdit;
  final Widget Function({
    required BuildContext context,
    required T info,
    required Future<void> Function() onRefresh,
    required VoidCallback? onEdit,
  }) buildScaffold;

  @override
  State<InfoDetailLoader<T>> createState() => _InfoDetailLoaderState<T>();
}

class _InfoDetailLoaderState<T> extends State<InfoDetailLoader<T>> {
  late Future<T?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load(forceRefresh: false);
  }

  Future<T?> _load({required bool forceRefresh}) async {
    final info = await widget.load(forceRefresh: forceRefresh);
    if (info != null && mounted) {
      Provider.of<AppContext>(context, listen: false)
          .analytics
          .logScreenView(screenName: widget.analyticsScreenName(info));
    }
    return info;
  }

  Future<void> _refresh() async {
    final pref = Provider.of<AppContext>(context, listen: false).sharedPref;
    if (!pref.canRefreshInfo) {
      await Future.delayed(kRefreshCooldownBusyWait);
      return;
    }
    pref.setInfoRefreshTime();
    setState(() {
      _future = _load(forceRefresh: false);
    });
    await _future;
  }

  Future<void> _openEditor(final T info) async {
    final changed = await widget.openEditor(context, info);
    if (!changed || !mounted) {
      return;
    }

    final refreshed = await widget.load(forceRefresh: true);
    if (!mounted) {
      return;
    }

    if (refreshed == null) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _future = Future<T?>.value(refreshed);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select((AppContext c) => c.currentUser);
    final canEdit = (widget.canEdit ?? (u) => u.canManageInfo)(user);

    return FutureBuilder<T?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: LoadProgressBody(
              message: 'Loading…',
              completedSteps: 0,
              totalSteps: 1,
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: Text(widget.pageTitleFallback)),
            body: LoadProgressBody(
              message: '',
              completedSteps: 0,
              totalSteps: 1,
              error: snapshot.error,
              errorTitle: 'Could not load page',
              onRetry: () {
                setState(() {
                  _future = _load(forceRefresh: true);
                });
              },
            ),
          );
        }

        final info = snapshot.data;
        if (info == null) {
          return Scaffold(
            appBar: AppBar(title: Text(widget.pageTitleFallback)),
            body: Center(child: Text(widget.notFoundMessage)),
          );
        }

        return widget.buildScaffold(
          context: context,
          info: info,
          onRefresh: _refresh,
          onEdit: canEdit ? () => _openEditor(info) : null,
        );
      },
    );
  }
}
