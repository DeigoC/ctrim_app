import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/cell_group.dart';
import '../../models/event/event_head.dart';
import '../../models/info/church_info.dart';
import '../../models/info/church_page.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import '../../utility/activity_time_series.dart';
import '../../utility/church_location_stats.dart';
import '../../utility/responsive_layout.dart';
import '../../widgets/common/activity_trend_section.dart';
import '../../widgets/information/info_image_carousel.dart';
import '../../widgets/information/info_section_card.dart';
import '../../widgets/paired_row_list.dart';
import '../../widgets/two_column_masonry.dart';
import '../../widgets/posts/post_head.dart';
import '../cell_groups/cell_group_detail_page.dart';
import 'church_pastors_page.dart';
import 'info_tab_widgets.dart';

class ChurchHubDashboard extends StatelessWidget {
  const ChurchHubDashboard({
    super.key,
    required this.church,
    required this.pages,
    required this.pagesError,
    required this.stats,
    required this.statsError,
    required this.canAddPages,
    required this.visiblePostLimit,
    this.onOpenMaps,
    required this.onOpenPastors,
    required this.onOpenPage,
    required this.onAddPage,
    required this.onRetryPages,
    required this.onRetryStats,
  });

  final ChurchInfo church;
  final List<ChurchPage> pages;
  final Object? pagesError;
  final ChurchLocationStats? stats;
  final Object? statsError;
  final bool canAddPages;
  final int visiblePostLimit;
  final VoidCallback? onOpenMaps;
  final VoidCallback onOpenPastors;
  final ValueChanged<ChurchPage> onOpenPage;
  final VoidCallback onAddPage;
  final VoidCallback onRetryPages;
  final VoidCallback onRetryStats;

  @override
  Widget build(BuildContext context) {
    context.select((AppContext c) => c.usersEpoch);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final cards = <Widget>[
      _VisitCard(church: church, onOpenMaps: onOpenMaps),
      if (church.hasPastorsSection)
        _PastorsCard(church: church, onLearnAbout: onOpenPastors),
      if (pagesError != null || pages.isNotEmpty || canAddPages)
        _PagesCard(
          pages: pages,
          pagesError: pagesError,
          canAdd: canAddPages,
          onRetry: onRetryPages,
          onOpenPage: onOpenPage,
          onAddPage: onAddPage,
        ),
      _SnapshotCard(
        church: church,
        stats: stats,
        statsError: statsError,
        onRetryStats: onRetryStats,
      ),
      if (church.hasGalleryImages) _GalleryCard(church: church),
      if (church.hasLocation)
        _RecentPostsCard(
          posts: stats?.posts ?? const [],
          visiblePostLimit: visiblePostLimit,
          loading: stats == null && statsError == null,
        ),
      if (church.hasLocation)
        _CellGroupsCard(
          groups: stats?.cellGroups ?? const [],
          loading: stats == null && statsError == null,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
        const SizedBox(height: 20),
        if (ResponsiveLayout.isWideScreenOf(context))
          TwoColumnMasonry(children: cards)
        else ...[
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            cards[i],
          ],
        ],
      ],
    );
  }
}

class _VisitCard extends StatelessWidget {
  const _VisitCard({required this.church, this.onOpenMaps});

  final ChurchInfo church;
  final VoidCallback? onOpenMaps;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InfoSectionCard(
      icon: Icons.place_outlined,
      title: l10n.churchHubFindUsTitle,
      subtitle: l10n.churchHubFindUsSubtitle,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Chip(
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
          ),
          if (church.hasAddress) ...[
            const SizedBox(height: 12),
            Text(
              church.address,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (onOpenMaps != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                onPressed: onOpenMaps,
                icon: const Icon(Icons.map_outlined),
                label: Text(l10n.churchHubOpenMaps),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PastorsCard extends StatelessWidget {
  const _PastorsCard({
    required this.church,
    required this.onLearnAbout,
  });

  final ChurchInfo church;
  final VoidCallback onLearnAbout;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return InfoSectionCard(
      icon: Icons.groups_outlined,
      title: l10n.churchHubPastorsTitle,
      subtitle: l10n.churchHubPastorsSubtitle,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (church.hasPastorsImage) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AdaptiveInfoGalleryImage(
                imageUrl: church.pastorsImageSrc,
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (church.hasPastors)
            ChurchPastorUserList(pastorUserIds: church.pastorUserIds),
          if (church.hasPastorsBody) ...[
            if (church.hasPastors || church.hasPastorsImage)
              const SizedBox(height: 8),
            FilledButton(
              onPressed: onLearnAbout,
              child: Text(l10n.churchHubLearnAboutPastors),
            ),
          ],
        ],
      ),
    );
  }
}

class _PagesCard extends StatelessWidget {
  const _PagesCard({
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

    Widget content;
    if (pagesError != null && pages.isEmpty) {
      content = Column(
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
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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

    return InfoSectionCard(
      icon: Icons.menu_book_outlined,
      title: l10n.churchHubPagesTitle,
      subtitle: l10n.churchHubPagesSubtitle,
      content: content,
    );
  }
}

class _SnapshotCard extends StatelessWidget {
  const _SnapshotCard({
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

    Widget content;
    if (!church.hasLocation) {
      content = Text(
        l10n.churchHubSetLocationHint,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      );
    } else if (statsError != null && stats == null) {
      content = Column(
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
    } else if (stats == null) {
      content = const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    } else {
      content = _SnapshotTiles(stats: stats!);
    }

    return InfoSectionCard(
      icon: Icons.insights_outlined,
      title: l10n.churchHubSnapshotTitle,
      subtitle: l10n.churchHubSnapshotSubtitle,
      content: content,
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
        final tilesSection = wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < tiles.length; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Expanded(child: tiles[i]),
                  ],
                ],
              )
            : Column(
                children: [
                  for (var i = 0; i < tiles.length; i++) ...[
                    if (i > 0) const SizedBox(height: 12),
                    tiles[i],
                  ],
                ],
              );

        final now = DateTime.now();
        final chartStart = ChurchLocationStats.queryRangeStart(now);
        final chartEnd = ChurchLocationStats.queryRangeEndExclusive(now);
        final countPoints = ActivityTimeSeries.fromPosts(
          posts: stats.posts,
          metric: ActivityTimeSeriesMetric.count,
          startInclusive: chartStart,
          endExclusive: chartEnd,
        );
        final attendancePoints = ActivityTimeSeries.fromPosts(
          posts: stats.posts,
          metric: ActivityTimeSeriesMetric.attendance,
          startInclusive: chartStart,
          endExclusive: chartEnd,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            tilesSection,
            const SizedBox(height: 20),
            ActivityTrendSection(
              title: l10n.churchHubActivityTrendTitle,
              subtitle: l10n.churchHubActivityTrendSubtitle,
              countLabel: l10n.churchHubActivityTrendMetricPosts,
              countPoints: countPoints,
              attendancePoints: attendancePoints,
              emptyMessage: l10n.activityTrendEmpty,
              weeklyHint: l10n.activityTrendWeeklyHint,
            ),
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

class _GalleryCard extends StatelessWidget {
  const _GalleryCard({required this.church});

  final ChurchInfo church;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final images = church.galleryImageSources;

    Widget gallery;
    if (images.length > 1) {
      gallery = LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 520) {
            return PairedRowList(
              itemCount: images.length,
              runSpacing: 12,
              itemBuilder: (_, index) => AdaptiveInfoGalleryImage(
                imageUrl: images[index],
              ),
            );
          }
          return Column(
            children: [
              for (var i = 0; i < images.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                AdaptiveInfoGalleryImage(imageUrl: images[i]),
              ],
            ],
          );
        },
      );
    } else {
      gallery = AdaptiveInfoGalleryImage(imageUrl: images.first);
    }

    return InfoSectionCard(
      icon: Icons.photo_library_outlined,
      title: l10n.churchHubGalleryTitle,
      subtitle: l10n.churchHubGallerySubtitle,
      content: gallery,
    );
  }
}

class _RecentPostsCard extends StatelessWidget {
  const _RecentPostsCard({
    required this.posts,
    required this.visiblePostLimit,
    required this.loading,
  });

  final List<EventHead> posts;
  final int visiblePostLimit;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final visible = posts.length > visiblePostLimit
        ? posts.take(visiblePostLimit).toList()
        : posts;
    final overflow = posts.length - visible.length;

    Widget content;
    if (loading) {
      content = const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    } else if (posts.isEmpty) {
      content = Text(
        l10n.churchHubNoRecentPosts,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
      );
    }

    return InfoSectionCard(
      icon: Icons.event_note_outlined,
      title: l10n.churchHubRecentPosts,
      subtitle: l10n.churchHubRecentPostsSubtitle,
      content: content,
    );
  }
}

class _CellGroupsCard extends StatelessWidget {
  const _CellGroupsCard({
    required this.groups,
    required this.loading,
  });

  final List<CellGroup> groups;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget content;
    if (loading) {
      content = const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    } else if (groups.isEmpty) {
      content = Text(
        l10n.churchHubNoCellGroups,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      );
    } else {
      content = Column(
        children: groups
            .map((group) => _hubCellGroupCard(
                  context,
                  l10n,
                  theme,
                  colorScheme,
                  group,
                ))
            .toList(),
      );
    }

    return InfoSectionCard(
      icon: Icons.groups_outlined,
      title: l10n.churchHubCellGroupsHere,
      subtitle: l10n.churchHubCellGroupsSubtitle,
      content: content,
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
