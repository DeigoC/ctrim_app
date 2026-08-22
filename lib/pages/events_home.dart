import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/event/event_head.dart';
import '../utility/app_context.dart';
import '../utility/bulletin_listing.dart';
import '../utility/event_heads_repository.dart';
import '../utility/refresh_cooldown.dart';
import '../utility/responsive_layout.dart';
import '../widgets/bulletin/bulletin_first_time_dialog.dart';
import '../widgets/bulletin/bulletin_setting_sheet.dart';
import '../widgets/posts/post_head.dart';
import '../utility/post_tag_helpers.dart';
import '../utility/volunteer_locations.dart';
import '../src/localization/app_localizations.dart';

class ViewEventsHome extends StatefulWidget {
  const ViewEventsHome(
      {super.key,
      required this.rebuildFunction,
      required this.scrollController});
  final Function() rebuildFunction;
  static const String _ctrimLogo = 'assets/images/ctrim_logo.png';
  final ScrollController scrollController;

  @override
  State<ViewEventsHome> createState() => _ViewEventsHomeState();
}

class _ViewEventsHomeState extends State<ViewEventsHome> {
  late final AppContext _appContext;
  final Set<String> _selectedPostTagIDs = {};
  late String _locationFilter;
  late BulletinSort _sort;
  late BulletinTimeFilter _timeFilter;
  late bool _bookmarksOnly;

  @override
  void initState() {
    super.initState();
    _appContext = Provider.of<AppContext>(context, listen: false);
    final prefs = _appContext.sharedPref;
    _sort = prefs.bulletinSort;
    _timeFilter = prefs.bulletinTimeFilter;
    _bookmarksOnly = prefs.bulletinBookmarksOnly;
    _locationFilter = VolunteerLocations.defaultFilterForUser(
      _appContext.currentUser.location,
      VolunteerLocations.assignableFrom(_appContext.allLocations),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_appContext.sharedPref.hasSeenBulletinDialog) {
        _showBulletinFirstTimeDialog();
      }
    });
  }

  BulletinListingQuery _listingQuery() {
    return BulletinListingQuery(
      sort: _sort,
      timeFilter: _timeFilter,
      bookmarksOnly: _bookmarksOnly,
      bookmarkedIds: _appContext.sharedPref.bookmarkedPosts.toSet(),
      selectedTagIDs: _selectedPostTagIDs,
      locationFilter: _locationFilter,
      now: DateTime.now(),
    );
  }

  void _persistListingPrefs() {
    final prefs = _appContext.sharedPref;
    prefs.setBulletinSort(_sort);
    prefs.setBulletinTimeFilter(_timeFilter);
    prefs.setBulletinBookmarksOnly(_bookmarksOnly);
  }

  void _logListingChange() {
    _appContext.analytics.logEvent(
      name: 'bulletin_listing',
      parameters: {
        'sort': _sort.name,
        'time': _timeFilter.name,
        'bookmarks': _bookmarksOnly ? '1' : '0',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    context.select((AppContext c) => (c.headsEpoch, c.catalogsEpoch));
    final appContext = _appContext;
    final query = _listingQuery();
    final heads = BulletinListing.apply(
      heads: appContext.eventHeads,
      query: query,
    );
    final int itemCount = heads.length;

    return RefreshIndicator(
      edgeOffset: kToolbarHeight + 20,
      backgroundColor: colorScheme.surface,
      color: colorScheme.primary,
      onRefresh: () => _onRefresh().then((value) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          behavior: !appContext.currentUser.isLeader
              ? SnackBarBehavior.floating
              : null,
          backgroundColor: colorScheme.inverseSurface,
          content: Row(
            children: [
              Icon(Icons.check_circle,
                  color: colorScheme.onInverseSurface, size: 20),
              const SizedBox(width: 8),
              Text(
                'You are up to date!',
                style: TextStyle(color: colorScheme.onInverseSurface),
              ),
            ],
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ));
      }),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double contentWidth = constraints.maxWidth;
          final bool isWideScreen = ResponsiveLayout.isWideScreen(contentWidth);
          final double maxWidth =
              ResponsiveLayout.maxContentWidth(contentWidth);
          final double horizontalPadding = isWideScreen
              ? ((contentWidth - maxWidth) / 2).clamp(16.0, double.infinity)
              : 8.0;

          return CustomScrollView(
            controller: widget.scrollController,
            key: const PageStorageKey<String>('events_page'),
            slivers: [
              SliverAppBar(
                title: Row(
                  children: [
                    Icon(
                      Icons.campaign,
                      color: colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Bulletin',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                centerTitle: false,
                floating: true,
                snap: true,
                expandedHeight: 100,
                backgroundColor: colorScheme.surface,
                surfaceTintColor: colorScheme.surfaceTint,
                actions: [
                  IconButton(
                    onPressed: () => _showFilterModel(context),
                    tooltip: l10n.bulletinSortTooltip,
                    style: IconButton.styleFrom(
                      backgroundColor:
                          colorScheme.primaryContainer.withValues(alpha: 0.3),
                      foregroundColor: colorScheme.primary,
                    ),
                    icon: Badge(
                      isLabelVisible: query.showsNonDefaultBanner,
                      child: const Icon(Icons.sort),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      ViewEventsHome._ctrimLogo,
                      fit: BoxFit.contain,
                      height: kToolbarHeight,
                      errorBuilder: (context, error, stackTrace) => Container(
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.church,
                          color: colorScheme.primary,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (query.showsNonDefaultBanner)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: _buildFilterIndicator(
                      appContext,
                      colorScheme,
                      l10n,
                      query,
                    ),
                  ),
                ),
              SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 8,
                ),
                sliver: itemCount == 0
                    ? _buildEmptyState(colorScheme, theme, l10n)
                    : isWideScreen
                        ? SliverToBoxAdapter(
                            child: _buildWidePostRows(colorScheme, heads),
                          )
                        : SliverList.separated(
                            itemCount: itemCount,
                            itemBuilder: (_, index) => _buildPostCard(
                              colorScheme,
                              heads[index],
                            ),
                            separatorBuilder:
                                (BuildContext context, int index) =>
                                    const SizedBox(height: 8),
                          ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          );
        },
      ),
    );
  }

  /// Paired rows so left-to-right, top-to-bottom stays chronological.
  Widget _buildWidePostRows(ColorScheme colorScheme, List<EventHead> heads) {
    final rows = <Widget>[];
    for (var i = 0; i < heads.length; i += 2) {
      if (i > 0) rows.add(const SizedBox(height: 16));
      final right = i + 1 < heads.length ? heads[i + 1] : null;
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildPostCard(colorScheme, heads[i], verticalMargin: 0),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: right == null
                ? const SizedBox.shrink()
                : _buildPostCard(colorScheme, right, verticalMargin: 0),
          ),
        ],
      ));
    }
    return Column(children: rows);
  }

  Widget _buildPostCard(
    ColorScheme colorScheme,
    EventHead head, {
    double verticalMargin = 4,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: verticalMargin),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: PostHead(
        thisHead: head,
        updatePost: () => widget.rebuildFunction(),
      ),
    );
  }

  Widget _buildFilterIndicator(
    AppContext appContext,
    ColorScheme colorScheme,
    AppLocalizations l10n,
    BulletinListingQuery query,
  ) {
    final selectedTags = PostTagHelpers.resolveTags(
      tagIDs: _selectedPostTagIDs.toList(),
      allTags: appContext.allPostTags,
    );
    final parts = <String>[];
    switch (query.sort) {
      case BulletinSort.eventDateSoonest:
        parts.add(l10n.bulletinSortSoonest);
      case BulletinSort.eventDateLatest:
        parts.add(l10n.bulletinSortLatest);
      case BulletinSort.relevancy:
        break;
    }
    switch (query.timeFilter) {
      case BulletinTimeFilter.upcoming:
        parts.add(l10n.bulletinShowUpcoming);
      case BulletinTimeFilter.past:
        parts.add(l10n.bulletinShowPast);
      case BulletinTimeFilter.all:
        break;
    }
    if (query.bookmarksOnly) parts.add(l10n.bulletinShowBookmarks);
    if (_locationFilter != VolunteerLocations.all) {
      parts.add(_locationFilter);
    }
    if (selectedTags.isNotEmpty) {
      parts.add(selectedTags.map((t) => t.name).join(', '));
    }

    final Color accent = switch (query.timeFilter) {
      BulletinTimeFilter.upcoming => Colors.green,
      BulletinTimeFilter.past => Colors.orange,
      BulletinTimeFilter.all when query.bookmarksOnly => Colors.purple,
      BulletinTimeFilter.all => colorScheme.primary,
    };

    return Tooltip(
      message: l10n.bulletinClearFilters,
      child: Material(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _clearListingPrefs,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: accent.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  query.bookmarksOnly
                      ? Icons.bookmark
                      : query.timeFilter == BulletinTimeFilter.upcoming
                          ? Icons.upcoming
                          : query.timeFilter == BulletinTimeFilter.past
                              ? Icons.history
                              : Icons.filter_alt,
                  size: 16,
                  color: accent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.bulletinShowing(parts.join(' · ')),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: accent,
                    ),
                  ),
                ),
                Icon(Icons.close, size: 16, color: accent),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    ColorScheme colorScheme,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const SizedBox(height: 60),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_note,
                size: 64,
                color: colorScheme.primary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.bulletinEmptyTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.bulletinEmptyBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.tonal(
              onPressed: () => _showFilterModel(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.filter_alt, size: 20),
                  const SizedBox(width: 8),
                  Text(l10n.bulletinChangeFilter),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterModel(final BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      showDragHandle: true,
      isScrollControlled: true,
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      builder: (_) => SafeArea(
        child: BulletinSettingSheet(
          sort: _sort,
          timeFilter: _timeFilter,
          bookmarksOnly: _bookmarksOnly,
          availableTags: _appContext.activePostTags,
          selectedTagIDs: Set<String>.from(_selectedPostTagIDs),
          locationOptions:
              VolunteerLocations.filterOptionsFrom(_appContext.allLocations),
          selectedLocation: _locationFilter,
          onSortChanged: (sort) {
            setState(() => _sort = sort);
            _persistListingPrefs();
            _logListingChange();
          },
          onTimeFilterChanged: (filter) {
            setState(() => _timeFilter = filter);
            _persistListingPrefs();
            _logListingChange();
          },
          onBookmarksOnlyChanged: (value) {
            setState(() => _bookmarksOnly = value);
            _persistListingPrefs();
            _logListingChange();
          },
          onLocationChanged: (location) {
            setState(() => _locationFilter = location);
          },
          onTagSelectionChanged: (selected) {
            setState(() {
              _selectedPostTagIDs
                ..clear()
                ..addAll(selected);
            });
          },
        ),
      ),
    );
  }

  void _clearListingPrefs() {
    HapticFeedback.selectionClick();
    setState(() {
      _sort = BulletinSort.relevancy;
      _timeFilter = BulletinTimeFilter.all;
      _bookmarksOnly = false;
      _selectedPostTagIDs.clear();
      _locationFilter = VolunteerLocations.all;
    });
    _persistListingPrefs();
    _logListingChange();
  }

  void _showBulletinFirstTimeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const BulletinFirstTimeDialog(),
    ).then((_) {
      _appContext.sharedPref.setHasSeenBulletinDialog();
    });
  }

  Future<void> _onRefresh() async {
    if (_appContext.sharedPref.canRefreshPosts) {
      debugPrint('refreshing now!');
      await _refreshPosts();
      _appContext.sharedPref.setPostRefreshTime();
    } else {
      debugPrint('cannot refresh cause of timer');
      await Future.delayed(kRefreshCooldownBusyWait);
    }
  }

  Future<void> _refreshPosts() async {
    final heads = await EventHeadsRepository().fetchEventHeads();
    setState(() {
      _appContext.setRefreshedHeads(heads);
    });
  }
}
