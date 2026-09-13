import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/event/event_head.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import '../../utility/bulletin_listing.dart';
import '../../utility/catalog/post_tag_helpers.dart';
import '../../utility/catalog/volunteer_locations.dart';
import '../../utility/dialog_manager.dart';
import '../../utility/responsive_layout.dart';
import '../../utility/user_schedule_service.dart';
import '../../widgets/bulletin/bulletin_setting_sheet.dart';
import '../../widgets/common/load_progress_body.dart';
import '../../widgets/posts/post_head.dart';
import '../../widgets/two_column_masonry.dart';

class ViewMyPostsPage extends StatefulWidget {
  const ViewMyPostsPage({super.key});

  static const List<BulletinSort> _sortOptions = [
    BulletinSort.recentDate,
    BulletinSort.eventDateSoonest,
    BulletinSort.eventDateLatest,
  ];

  @override
  State<ViewMyPostsPage> createState() => _ViewMyPostsPageState();
}

class _ViewMyPostsPageState extends State<ViewMyPostsPage> {
  late final AppContext _appContext;
  final UserScheduleService _scheduleService = UserScheduleService();
  final Set<String> _selectedPostTagIDs = {};

  BulletinSort _sort = BulletinSort.recentDate;
  BulletinTimeFilter _timeFilter = BulletinTimeFilter.all;
  late String _locationFilter;

  bool _loading = false;
  Object? _loadError;
  String _statusMessage = '';
  int _completedSteps = 0;
  int _totalSteps = 2;

  @override
  void initState() {
    _appContext = Provider.of(context, listen: false);
    _locationFilter = VolunteerLocations.all;
    super.initState();
    if (_appContext.currentUser.posts == null) {
      _loading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadPosts();
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _pruneStalePosts());
    }
  }

  BulletinListingQuery _listingQuery() {
    return BulletinListingQuery(
      sort: _sort,
      timeFilter: _timeFilter,
      selectedTagIDs: _selectedPostTagIDs,
      locationFilter: _locationFilter,
      excludePeriodParents: false,
      defaultSort: BulletinSort.recentDate,
      now: DateTime.now(),
    );
  }

  Future<void> _loadPosts() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _loading = true;
      _loadError = null;
      _statusMessage = l10n.myPostsFetching;
      _completedSteps = 0;
      _totalSteps = 2;
    });

    try {
      final posts =
          await _scheduleService.fetchPosts(_appContext.currentUser.id);
      if (!mounted) return;

      setState(() {
        _completedSteps = 1;
        _statusMessage = l10n.myPostsCleaning;
      });

      _appContext.currentUser.setPosts(posts);
      await _pruneStalePosts();
      if (!mounted) return;

      setState(() {
        _loading = false;
        _completedSteps = 2;
        _statusMessage = l10n.myPostsDone;
      });
    } catch (e, st) {
      debugPrint('Error fetching my posts: $e\n$st');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    context.select((AppContext c) => (c.headsEpoch, c.catalogsEpoch));
    final query = _listingQuery();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myPostsTitle),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        actions: [
          IconButton(
            onPressed: () => _showFilterSheet(context),
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
          IconButton(
            onPressed: _onHelpClick,
            icon: const Icon(Icons.help_outline),
          ),
        ],
      ),
      body: _buildBody(l10n, query),
    );
  }

  Widget _buildBody(AppLocalizations l10n, BulletinListingQuery query) {
    if (_loading || _loadError != null) {
      return LoadProgressBody(
        message: _statusMessage.isEmpty ? l10n.myPostsLoading : _statusMessage,
        completedSteps: _completedSteps,
        totalSteps: _totalSteps,
        error: _loadError,
        errorTitle: l10n.myPostsLoadError,
        onRetry: _loadPosts,
      );
    }

    if (_appContext.currentUser.posts == null) {
      return LoadProgressBody(
        message: l10n.myPostsLoading,
        completedSteps: 0,
        totalSteps: 1,
        onRetry: _loadPosts,
      );
    }

    return _buildBodyWithData(l10n, query);
  }

  Widget _buildBodyWithData(AppLocalizations l10n, BulletinListingQuery query) {
    final involvementIds = _appContext.currentUser.posts!
        .map((e) => e.postID)
        .where((id) => _appContext.headById(id) != null)
        .toSet();
    final involvedHeads = involvementIds
        .map((id) => _appContext.headById(id)!)
        .toList(growable: false);
    final heads = BulletinListing.apply(heads: involvedHeads, query: query);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasAnyPosts = involvedHeads.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double contentWidth = constraints.maxWidth;
        final bool isWideScreen = ResponsiveLayout.isWideScreenOf(context);
        final double horizontalPadding = isWideScreen
            ? ((contentWidth - ResponsiveLayout.maxContentWidth(contentWidth)) /
                    2)
                .clamp(16.0, double.infinity)
            : 8.0;

        return CustomScrollView(
          slivers: [
            if (query.showsNonDefaultBanner)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    8,
                    horizontalPadding,
                    8,
                  ),
                  child: _buildFilterIndicator(colorScheme, l10n, query),
                ),
              ),
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 8,
              ),
              sliver: heads.isEmpty
                  ? SliverToBoxAdapter(
                      child: _buildEmptyState(
                        colorScheme: colorScheme,
                        theme: theme,
                        l10n: l10n,
                        hasAnyPosts: hasAnyPosts,
                      ),
                    )
                  : isWideScreen
                      ? SliverToBoxAdapter(
                          child: TwoColumnMasonry(
                            children: [
                              for (final head in heads) _buildPostCard(head),
                            ],
                          ),
                        )
                      : SliverList.separated(
                          itemCount: heads.length,
                          itemBuilder: (_, index) =>
                              _buildPostCard(heads[index]),
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                        ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        );
      },
    );
  }

  Widget _buildPostCard(EventHead head) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
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
        updatePost: () {
          setState(() {});
        },
      ),
    );
  }

  Widget _buildFilterIndicator(
    ColorScheme colorScheme,
    AppLocalizations l10n,
    BulletinListingQuery query,
  ) {
    final selectedTags = PostTagHelpers.resolveTags(
      tagIDs: _selectedPostTagIDs.toList(),
      allTags: _appContext.allPostTags,
    );
    final parts = <String>[];
    switch (query.sort) {
      case BulletinSort.eventDateSoonest:
        parts.add(l10n.bulletinSortSoonest);
      case BulletinSort.eventDateLatest:
        parts.add(l10n.bulletinSortLatest);
      case BulletinSort.recentDate:
        break;
      case BulletinSort.relevancy:
        parts.add(l10n.bulletinSortRelevancy);
    }
    switch (query.timeFilter) {
      case BulletinTimeFilter.upcoming:
        parts.add(l10n.bulletinShowUpcoming);
      case BulletinTimeFilter.past:
        parts.add(l10n.bulletinShowPast);
      case BulletinTimeFilter.undated:
        parts.add(l10n.bulletinShowUndated);
      case BulletinTimeFilter.all:
        break;
    }
    if (_locationFilter != VolunteerLocations.all) {
      parts.add(_locationFilter);
    }
    if (selectedTags.isNotEmpty) {
      parts.add(selectedTags.map((t) => t.name).join(', '));
    }

    final Color accent = switch (query.timeFilter) {
      BulletinTimeFilter.upcoming => Colors.green,
      BulletinTimeFilter.past => Colors.orange,
      BulletinTimeFilter.undated => Colors.blueGrey,
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
                  switch (query.timeFilter) {
                    BulletinTimeFilter.upcoming => Icons.upcoming,
                    BulletinTimeFilter.past => Icons.history,
                    BulletinTimeFilter.undated => Icons.event_busy,
                    BulletinTimeFilter.all => Icons.filter_alt,
                  },
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

  Widget _buildEmptyState({
    required ColorScheme colorScheme,
    required ThemeData theme,
    required AppLocalizations l10n,
    required bool hasAnyPosts,
  }) {
    return Padding(
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
              hasAnyPosts ? Icons.filter_alt_off : Icons.event_note,
              size: 64,
              color: colorScheme.primary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            hasAnyPosts ? l10n.bulletinEmptyTitle : l10n.myPostsEmptyTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasAnyPosts ? l10n.bulletinEmptyBody : l10n.myPostsEmptyBody,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              height: 1.4,
            ),
          ),
          if (hasAnyPosts) ...[
            const SizedBox(height: 24),
            FilledButton.tonal(
              onPressed: () => _showFilterSheet(context),
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
        ],
      ),
    );
  }

  void _showFilterSheet(final BuildContext context) {
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
          bookmarksOnly: false,
          showBookmarksFilter: false,
          availableSorts: ViewMyPostsPage._sortOptions,
          availableTags: _appContext.activePostTags,
          selectedTagIDs: Set<String>.from(_selectedPostTagIDs),
          locationOptions:
              VolunteerLocations.filterOptionsFrom(_appContext.allLocations),
          selectedLocation: _locationFilter,
          onSortChanged: (sort) => setState(() => _sort = sort),
          onTimeFilterChanged: (filter) =>
              setState(() => _timeFilter = filter),
          onBookmarksOnlyChanged: (_) {},
          onLocationChanged: (location) =>
              setState(() => _locationFilter = location),
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
      _sort = BulletinSort.recentDate;
      _timeFilter = BulletinTimeFilter.all;
      _selectedPostTagIDs.clear();
      _locationFilter = VolunteerLocations.all;
    });
  }

  void _onHelpClick() {
    final l10n = AppLocalizations.of(context)!;
    DialogManager.showAlertDialog(
      context: context,
      title: l10n.myPostsHelpTitle,
      content: l10n.myPostsHelpBody,
    );
  }

  Future<void> _pruneStalePosts() async {
    await _scheduleService.pruneStalePostInvolvements(
      user: _appContext.currentUser,
      eventHeads: _appContext.eventHeads,
    );
  }
}
