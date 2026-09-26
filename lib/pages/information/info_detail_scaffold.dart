import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../utility/app_analytics.dart';
import '../../utility/app_context.dart';
import '../../utility/cache/refresh_cooldown.dart';
import '../../widgets/common/load_progress_body.dart';
import 'info_detail_body.dart';

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
    this.galleryImageUrls,
    this.aboveBody,
    this.bodyHeading,
    this.belowBody,
    this.pinPortraitAside = false,
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
  final List<String>? galleryImageUrls;
  final Widget? aboveBody;
  final Widget? bodyHeading;
  final Widget? belowBody;

  /// Wide windows pin a portrait or square lead photo beside the story.
  /// Testimonials and Pastors & History opt in. Landscape photos and narrow
  /// windows keep the banner. Leave this off for church hubs, CTRIM topics,
  /// and nested church pages.
  final bool pinPortraitAside;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pageBody = pinPortraitAside
        ? InfoDetailAsideHost(
            imageUrls: imageUrls,
            heroTag: heroTag,
            body: body,
            header: header,
            onRefresh: onRefresh,
            showCarouselWhenEmpty: showCarouselWhenEmpty,
            carouselHeightFraction: carouselHeightFraction,
            galleryImageUrls: galleryImageUrls,
            aboveBody: aboveBody,
            bodyHeading: bodyHeading,
            belowBody: belowBody,
          )
        : InfoDetailStackedBody(
            imageUrls: imageUrls,
            heroTag: heroTag,
            body: body,
            header: header,
            onRefresh: onRefresh,
            showCarouselWhenEmpty: showCarouselWhenEmpty,
            carouselHeightFraction: carouselHeightFraction,
            galleryImageUrls: galleryImageUrls,
            aboveBody: aboveBody,
            bodyHeading: bodyHeading,
            belowBody: belowBody,
          );

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
      body: pageBody,
    );
  }
}

/// Stateful wrapper that loads one info document, logs analytics, and supports edit/refresh.
class InfoDetailLoader<T> extends StatefulWidget {
  const InfoDetailLoader({
    super.key,
    required this.load,
    required this.logScreen,
    required this.pageTitleFallback,
    required this.notFoundMessage,
    required this.openEditor,
    required this.buildScaffold,
    this.initialInfo,
    this.canEdit,
  });

  final Future<T?> Function({required bool forceRefresh}) load;
  final void Function(AppAnalytics analytics, T info) logScreen;
  final String pageTitleFallback;
  final String notFoundMessage;
  final Future<bool> Function(BuildContext context, T info) openEditor;

  /// Record already on screen (list or hub card). Paints the shared image on
  /// the first frame so the hero can fly while a refresh runs behind it.
  final T? initialInfo;
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
  T? _info;
  Object? _error;
  bool _loading = true;
  bool _loggedView = false;

  @override
  void initState() {
    super.initState();
    _info = widget.initialInfo;
    _loading = _info == null;
    if (_info != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _info != null) _logScreen(_info as T);
      });
    }
    _load(forceRefresh: false);
  }

  void _logScreen(final T info) {
    if (_loggedView) return;
    _loggedView = true;
    widget.logScreen(
      Provider.of<AppContext>(context, listen: false).analytics,
      info,
    );
  }

  Future<void> _load({required bool forceRefresh}) async {
    final hadInfo = _info != null;
    if (!hadInfo && _error != null && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final info = await widget.load(forceRefresh: forceRefresh);
      if (!mounted) return;
      if (info != null) _logScreen(info);
      setState(() {
        _loading = false;
        _error = null;
        if (info != null || !hadInfo) {
          _info = info;
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_info == null) _error = error;
      });
    }
  }

  Future<void> _refresh() async {
    final pref = Provider.of<AppContext>(context, listen: false).sharedPref;
    if (!pref.canRefreshInfo) {
      await Future.delayed(kRefreshCooldownBusyWait);
      return;
    }
    pref.setInfoRefreshTime();
    await _load(forceRefresh: false);
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
      _info = refreshed;
      _loading = false;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select((AppContext c) => c.currentUser);
    final canEdit = (widget.canEdit ?? (u) => u.canManageInfo)(user);
    final info = _info;

    if (info != null) {
      return widget.buildScaffold(
        context: context,
        info: info,
        onRefresh: _refresh,
        onEdit: canEdit ? () => _openEditor(info) : null,
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.pageTitleFallback)),
        body: LoadProgressBody(
          message: '',
          completedSteps: 0,
          totalSteps: 1,
          error: _error,
          errorTitle: 'Could not load page',
          onRetry: () => _load(forceRefresh: true),
        ),
      );
    }

    if (_loading) {
      return const Scaffold(
        body: LoadProgressBody(
          message: 'Loading…',
          completedSteps: 0,
          totalSteps: 1,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.pageTitleFallback)),
      body: Center(child: Text(widget.notFoundMessage)),
    );
  }
}
