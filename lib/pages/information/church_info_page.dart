import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../firebase/db_managers/event_db_manager.dart';
import '../../models/cell_group.dart';
import '../../models/event/event_head.dart';
import '../../models/info/church_info.dart';
import '../../models/info/church_page.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import '../../utility/church_location_stats.dart';
import '../../utility/info_repository.dart';
import '../../utility/cache/refresh_cooldown.dart';
import '../../utility/responsive_layout.dart';
import '../../widgets/common/load_progress_body.dart';
import '../../widgets/paired_row_list.dart';
import '../../widgets/posts/post_head.dart';
import '../cell_groups/cell_group_detail_page.dart';
import 'church_page_info_page.dart';
import 'edit_info_body_page.dart';
import 'info_detail_scaffold.dart';
import 'info_tab_widgets.dart';

class ChurchInfoPage extends StatefulWidget {
  const ChurchInfoPage({super.key, required this.documentId});

  final String documentId;

  /// Matches cell-group meeting trail length (`fetchMeetingTrail` limit).
  static const int _visiblePostLimit = 4;

  @override
  State<ChurchInfoPage> createState() => _ChurchInfoPageState();
}

class _ChurchInfoPageState extends State<ChurchInfoPage> {
  final InfoRepository _repository = InfoRepository();
  final EventHeadDBManager _eventHeads = EventHeadDBManager();

  bool _loading = true;
  Object? _error;
  ChurchInfo? _church;
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
      final church = await _repository.fetchChurchById(
        widget.documentId,
        forceRefresh: forceRefresh,
      );
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
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChurchPageInfoPage(
          churchId: page.churchId,
          documentId: page.id,
        ),
      ),
    );
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

    return InfoDetailPageScaffold(
      title: church.title,
      imageUrls: church.imageSources,
      heroTag: 'info_church_${church.id}',
      body: church.body,
      onRefresh: _onRefresh,
      onEdit: canManageInfo ? () => _openEditor(church) : null,
      editTooltip: l10n.churchInfoEditTooltip,
      header: _ChurchHubHeader(
        church: church,
        onOpenMaps: church.hasMapLink ? () => _openMaps(church.mapLink) : null,
      ),
      aboveBody: _ChurchHubPages(
        pages: _pages,
        pagesError: _pagesError,
        canAdd: canManageChurchPages,
        onRetry: () => _load(forceRefresh: false),
        onOpenPage: _openChurchPage,
        onAddPage: () => _openAddPage(church),
      ),
      bodyHeading: Text(
        l10n.churchHubAboutTitle,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
      belowBody: _ChurchHubSnapshot(
        church: church,
        stats: _stats,
        statsError: _statsError,
        onRetryStats: () => _load(forceRefresh: false),
      ),
    );
  }
}

class _ChurchHubHeader extends StatelessWidget {
  const _ChurchHubHeader({
    required this.church,
    this.onOpenMaps,
  });

  final ChurchInfo church;
  final VoidCallback? onOpenMaps;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          church.title,
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (church.summary.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            church.summary,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Chip(
              avatar: Icon(
                Icons.place_outlined,
                size: 18,
                color: colorScheme.primary,
              ),
              label: Text(
                church.hasLocation
                    ? church.location
                    : l10n.churchHubLocationUnset,
              ),
            ),
            if (onOpenMaps != null)
              OutlinedButton.icon(
                onPressed: onOpenMaps,
                icon: const Icon(Icons.map_outlined),
                label: Text(l10n.churchHubOpenMaps),
              ),
          ],
        ),
        if (church.hasAddress) ...[
          const SizedBox(height: 8),
          Text(
            church.address,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _ChurchHubSnapshot extends StatelessWidget {
  const _ChurchHubSnapshot({
    required this.church,
    required this.stats,
    required this.statsError,
    required this.onRetryStats,
  });

  final ChurchInfo church;
  final ChurchLocationStats? stats;
  final Object? statsError;
  final VoidCallback onRetryStats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!church.hasLocation) {
      return Text(
        l10n.churchHubSetLocationHint,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }

    final ChurchLocationStats? loadedStats = stats;

    if (statsError != null && loadedStats == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.churchHubStatsError,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.error,
            ),
          ),
          TextButton(
            onPressed: onRetryStats,
            child: Text(l10n.churchHubStatsRetry),
          ),
        ],
      );
    }

    if (loadedStats == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.churchHubSnapshotTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _SnapshotTiles(stats: loadedStats),
        const SizedBox(height: 20),
        _RecentPostsList(posts: loadedStats.posts),
        const SizedBox(height: 20),
        _CellGroupsList(groups: loadedStats.cellGroups),
      ],
    );
  }
}

class _SnapshotTiles extends StatelessWidget {
  const _SnapshotTiles({required this.stats});

  final ChurchLocationStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tiles = [
      _HubStatTile(
        icon: Icons.event_note_outlined,
        value: '${stats.postCount}',
        label: l10n.churchHubPostsLabel,
        hint: l10n.churchHubPostsHint,
      ),
      _HubStatTile(
        icon: Icons.groups_outlined,
        value: '${stats.cellGroupCount}',
        label: l10n.churchHubCellGroupsLabel,
        hint: l10n.churchHubCellGroupsHint,
      ),
      _HubStatTile(
        icon: Icons.people_outline,
        value: '${stats.peopleCount}',
        label: l10n.churchHubPeopleLabel,
        hint: l10n.churchHubPeopleHint,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 520;
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < tiles.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(child: tiles[i]),
              ],
            ],
          );
        }
        return Column(
          children: [
            for (var i = 0; i < tiles.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              tiles[i],
            ],
          ],
        );
      },
    );
  }
}

class _HubStatTile extends StatelessWidget {
  const _HubStatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.hint,
  });

  final IconData icon;
  final String value;
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: colorScheme.primary, size: 28),
          const SizedBox(height: 10),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentPostsList extends StatelessWidget {
  const _RecentPostsList({required this.posts});

  final List<EventHead> posts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final visible = posts.length > ChurchInfoPage._visiblePostLimit
        ? posts.take(ChurchInfoPage._visiblePostLimit).toList()
        : posts;
    final overflow = posts.length - visible.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.churchHubRecentPosts,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (posts.isEmpty)
          Text(
            l10n.churchHubNoRecentPosts,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else ...[
          if (ResponsiveLayout.isWideScreenOf(context))
            PairedRowList(
              itemCount: visible.length,
              runSpacing: 8,
              itemBuilder: (_, index) => PostHead(
                thisHead: visible[index],
                updatePost: () {},
              ),
            )
          else
            ...visible.map(
              (head) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: PostHead(
                  thisHead: head,
                  updatePost: () {},
                ),
              ),
            ),
          if (overflow > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l10n.churchHubMorePosts(overflow),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _CellGroupsList extends StatelessWidget {
  const _CellGroupsList({required this.groups});

  final List<CellGroup> groups;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.churchHubCellGroupsHere,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (groups.isEmpty)
          Text(
            l10n.churchHubNoCellGroups,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          )
        else if (ResponsiveLayout.isWideScreenOf(context))
          PairedRowList(
            itemCount: groups.length,
            runSpacing: 8,
            itemBuilder: (_, index) => _hubCellGroupCard(
              context,
              l10n,
              theme,
              colorScheme,
              groups[index],
            ),
          )
        else
          ...groups.map((group) => _hubCellGroupCard(
                context,
                l10n,
                theme,
                colorScheme,
                group,
              )),
      ],
    );
  }

  Widget _hubCellGroupCard(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    ColorScheme colorScheme,
    CellGroup group,
  ) {
    final cadence = group.cadenceLabel;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          Icons.groups_outlined,
          color: colorScheme.primary,
        ),
        title: Text(group.name),
        subtitle: cadence.isEmpty ? null : Text(cadence),
        trailing: group.isPaused
            ? Text(
                l10n.cellGroupsStatusPaused,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.tertiary,
                  fontWeight: FontWeight.w600,
                ),
              )
            : null,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CellGroupDetailPage(groupId: group.id),
            ),
          );
        },
      ),
    );
  }
}

class _ChurchHubPages extends StatelessWidget {
  const _ChurchHubPages({
    required this.pages,
    required this.pagesError,
    required this.canAdd,
    required this.onRetry,
    required this.onOpenPage,
    required this.onAddPage,
  });

  final List<ChurchPage> pages;
  final Object? pagesError;
  final bool canAdd;
  final VoidCallback onRetry;
  final ValueChanged<ChurchPage> onOpenPage;
  final VoidCallback onAddPage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (pagesError != null && pages.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.churchHubPagesError,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.error,
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(l10n.churchHubPagesRetry),
          ),
        ],
      );
    }

    if (pages.isEmpty && !canAdd) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.churchHubPagesTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (pages.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              l10n.churchHubNoPages,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          ...pages.map(
            (page) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InfoTopicListCard(
                title: page.title,
                description: page.summary,
                imageUrl: page.imgSrc,
                heroTag: 'info_church_page_${page.churchId}_${page.id}',
                fallbackIcon: Icons.article_outlined,
                onTap: () => onOpenPage(page),
              ),
            ),
          ),
        if (canAdd)
          InfoAddContentCard(
            label: l10n.churchHubAddPage,
            description: l10n.churchHubAddPageDescription,
            onTap: onAddPage,
            compact: true,
          ),
      ],
    );
  }
}
