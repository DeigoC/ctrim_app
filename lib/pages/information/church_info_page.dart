import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../firebase/db_managers/event_db_manager.dart';
import '../../models/info/church_info.dart';
import '../../models/info/church_page.dart';
import '../../models/info/church_social.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import '../../utility/app_links.dart';
import '../../utility/church_hierarchy.dart';
import '../../utility/church_location_stats.dart';
import '../../utility/info_repository.dart';
import '../../utility/cache/refresh_cooldown.dart';
import '../../utility/responsive_layout.dart';
import '../../widgets/common/load_progress_body.dart';
import '../../widgets/media/cached_image_widget.dart';
import 'church_hub_dashboard.dart';
import 'edit_info_body_page.dart';

class ChurchInfoPage extends StatefulWidget {
  const ChurchInfoPage({super.key, required this.documentId});

  final String documentId;

  /// Matches cell-group meeting trail length (`fetchMeetingTrail` limit).
  static const int visiblePostLimit = 4;

  @override
  State<ChurchInfoPage> createState() => _ChurchInfoPageState();
}

class _ChurchInfoPageState extends State<ChurchInfoPage> {
  final InfoRepository _repository = InfoRepository();
  final EventHeadDBManager _eventHeads = EventHeadDBManager();

  bool _loading = true;
  Object? _error;
  ChurchInfo? _church;
  List<ChurchInfo> _allChurches = const [];
  ChurchLocationStats? _stats;
  Object? _statsError;
  List<ChurchPage> _pages = const [];
  Object? _pagesError;

  @override
  void initState() {
    super.initState();
    _load(forceRefresh: false);
  }

  Future<void> _load({required bool forceRefresh}) async {
    final appContext = Provider.of<AppContext>(context, listen: false);
    setState(() {
      _loading = true;
      _error = null;
      _statsError = null;
      _pagesError = null;
    });
    try {
      final churches = await _repository.fetchChurches(
        forceRefresh: forceRefresh,
      );
      ChurchInfo? church;
      for (final candidate in churches) {
        if (candidate.id == widget.documentId) {
          church = candidate;
          break;
        }
      }
      if (!mounted) return;

      ChurchLocationStats? stats;
      Object? statsError;
      List<ChurchPage> pages = const [];
      Object? pagesError;
      if (church != null) {
        final pagesFuture = _repository.fetchChurchPages(
          church.id,
          forceRefresh: forceRefresh,
        );
        if (church.hasLocation) {
          try {
            stats = await _loadStats(church, appContext);
          } catch (e) {
            statsError = e;
          }
        }
        try {
          pages = await pagesFuture;
        } catch (e) {
          pagesError = e;
        }
      }

      if (church != null) {
        appContext.analytics.logScreenView(
          screenName: 'Church Info: ${church.analyticsTitle}',
        );
      }

      if (!mounted) return;
      setState(() {
        _allChurches = churches;
        _church = church;
        if (church == null) {
          _stats = null;
          _statsError = null;
          _pages = const [];
          _pagesError = null;
        } else {
          if (!church.hasLocation) {
            _stats = null;
            _statsError = null;
          } else if (stats != null) {
            _stats = stats;
            _statsError = null;
          } else {
            _statsError = statsError;
          }
          if (pagesError == null) {
            _pages = pages;
            _pagesError = null;
          } else {
            _pagesError = pagesError;
          }
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<ChurchLocationStats> _loadStats(
    final ChurchInfo church,
    final AppContext appContext,
  ) async {
    final clock = DateTime.now();
    final heads = await _eventHeads.fetchHeadsWithEventDateInRange(
      startInclusive: ChurchLocationStats.queryRangeStart(clock),
      endExclusive: ChurchLocationStats.queryRangeEndExclusive(clock),
    );
    return ChurchLocationStats.compute(
      location: church.location,
      heads: heads,
      groups: appContext.allCellGroups,
      users: appContext.allUsers,
      now: clock,
    );
  }

  Future<void> _onRefresh() async {
    final pref = Provider.of<AppContext>(context, listen: false).sharedPref;
    if (!pref.canRefreshInfo) {
      await Future.delayed(kRefreshCooldownBusyWait);
      return;
    }
    pref.setInfoRefreshTime();
    await _load(forceRefresh: true);
  }

  Future<void> _openEditor(final ChurchInfo info) async {
    final changed = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => EditInfoBodyPage.forChurch(info: info),
          ),
        ) ??
        false;
    if (changed && mounted) {
      await _load(forceRefresh: true);
    }
  }

  Future<void> _openChurchPage(final ChurchPage page) async {
    await AppLinks.openChurchPage(
      context,
      churchId: page.churchId,
      pageId: page.id,
    );
    if (mounted) {
      await _load(forceRefresh: false);
    }
  }

  Future<void> _openPastors(final ChurchInfo church) async {
    await AppLinks.openChurchPastors(context, churchId: church.id);
    if (mounted) {
      await _load(forceRefresh: false);
    }
  }

  Future<void> _openAddPage(final ChurchInfo church) async {
    final changed = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => EditInfoBodyPage.forChurchPage(churchId: church.id),
          ),
        ) ??
        false;
    if (changed && mounted) {
      await _load(forceRefresh: true);
    }
  }

  Future<void> _openAddOutreach(final ChurchInfo parent) async {
    final changed = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => EditInfoBodyPage.forChurch(
              parentChurchId: parent.id,
            ),
          ),
        ) ??
        false;
    if (changed && mounted) {
      await _load(forceRefresh: true);
    }
  }

  Future<void> _openOutreach(final ChurchInfo outreach) async {
    await AppLinks.openChurch(context, id: outreach.id);
    if (mounted) {
      await _load(forceRefresh: false);
    }
  }

  Future<void> _openParent(final ChurchInfo parent) async {
    await AppLinks.openChurch(context, id: parent.id);
    if (mounted) {
      await _load(forceRefresh: false);
    }
  }

  Future<void> _openMaps(final String url) async {
    await launchUrlString(url, mode: LaunchMode.externalApplication)
        .onError((error, stackTrace) async {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
      return false;
    });
  }

  Future<void> _openSocial(final ChurchSocialLink link) async {
    await _openMaps(link.url);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canManageInfo =
        context.select((AppContext c) => c.currentUser.canManageInfo);
    final canManageChurchPages =
        context.select((AppContext c) => c.currentUser.canManageChurchPages);

    if (_loading && _church == null) {
      return const Scaffold(
        body: LoadProgressBody(
          message: 'Loading…',
          completedSteps: 0,
          totalSteps: 1,
        ),
      );
    }

    if (_error != null && _church == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.churchInfoPageTitle)),
        body: LoadProgressBody(
          message: '',
          completedSteps: 0,
          totalSteps: 1,
          error: _error,
          errorTitle: l10n.churchInfoLoadError,
          onRetry: () => _load(forceRefresh: true),
        ),
      );
    }

    final church = _church;
    if (church == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.churchInfoPageTitle)),
        body: Center(child: Text(l10n.churchInfoNotFound)),
      );
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.sizeOf(context);
    final double gutter =
        ResponsiveLayout.horizontalGutter(size.width, narrowPadding: 0);
    final maxWidth = ResponsiveLayout.maxContentWidth(size.width);
    final hasHero = church.hasHeroImage;
    // Match post / cell-group key-graphic AppBars: edge-to-edge cover.
    final double? heroHeight = hasHero ? size.height * 0.33 : null;
    final parent = ChurchHierarchy.parentOf(_allChurches, church);
    final outreaches = ChurchHierarchy.outreachesOf(_allChurches, church.id);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: heroHeight,
              title: Text(church.title),
              backgroundColor: colorScheme.surface,
              surfaceTintColor: colorScheme.surfaceTint,
              flexibleSpace: hasHero
                  ? FlexibleSpaceBar(
                      background: CachedImageWidget(
                        imageUrl: church.heroImageSrc,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        heroTag: 'info_church_${church.id}',
                      ),
                    )
                  : null,
              actions: [
                if (canManageInfo)
                  IconButton(
                    onPressed: () => _openEditor(church),
                    icon: const Icon(Icons.edit),
                    tooltip: l10n.churchInfoEditTooltip,
                  ),
              ],
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(gutter + 16, 20, gutter + 16, 40),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: ChurchHubDashboard(
                      church: church,
                      pages: _pages,
                      pagesError: _pagesError,
                      stats: _stats,
                      statsError: _statsError,
                      canAddPages: canManageChurchPages,
                      canManageInfo: canManageInfo,
                      visiblePostLimit: ChurchInfoPage.visiblePostLimit,
                      parentChurch: parent,
                      outreaches: outreaches,
                      onOpenMaps: church.hasMapLink
                          ? () => _openMaps(church.mapLink)
                          : null,
                      onOpenSocial: _openSocial,
                      onOpenParent:
                          parent == null ? null : () => _openParent(parent),
                      onOpenPastors: () => _openPastors(church),
                      onOpenPage: _openChurchPage,
                      onAddPage: () => _openAddPage(church),
                      onOpenOutreach: _openOutreach,
                      onAddOutreach: () => _openAddOutreach(church),
                      onRetryPages: () => _load(forceRefresh: false),
                      onRetryStats: () => _load(forceRefresh: false),
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
