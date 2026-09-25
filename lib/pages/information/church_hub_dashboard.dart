import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/cell_group.dart';
import '../../models/event/event_head.dart';
import '../../models/info/church_info.dart';
import '../../models/info/church_page.dart';
import '../../models/info/church_social.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import '../../utility/activity_time_series.dart';
import '../../utility/church_location_stats.dart';
import '../../utility/church_social_ui.dart';
import '../../utility/responsive_layout.dart';
import '../../widgets/common/activity_trend_section.dart';
import '../../widgets/information/info_image_carousel.dart';
import '../../widgets/information/info_section_card.dart';
import '../../widgets/paired_row_list.dart';
import '../../widgets/two_column_masonry.dart';
import '../../widgets/posts/post_head.dart';
import '../../utility/app_links.dart';
import '../cell_groups/cell_groups_at_location_page.dart';
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
    required this.canManageInfo,
    required this.visiblePostLimit,
    this.visibleCellGroupLimit = 3,
    this.parentChurch,
    this.outreaches = const [],
    this.onOpenMaps,
    this.onOpenParent,
    this.onOpenSocial,
    required this.onOpenPastors,
    required this.onOpenPage,
    required this.onAddPage,
    this.onOpenOutreach,
    this.onAddOutreach,
    required this.onRetryPages,
    required this.onRetryStats,
  });

  final ChurchInfo church;
  final List<ChurchPage> pages;
  final Object? pagesError;
  final ChurchLocationStats? stats;
  final Object? statsError;
  final bool canAddPages;
  final bool canManageInfo;
  final int visiblePostLimit;
  final int visibleCellGroupLimit;
  final ChurchInfo? parentChurch;
  final List<ChurchInfo> outreaches;
  final VoidCallback? onOpenMaps;
  final VoidCallback? onOpenParent;
  final ValueChanged<ChurchSocialLink>? onOpenSocial;
  final VoidCallback onOpenPastors;
  final ValueChanged<ChurchPage> onOpenPage;
  final VoidCallback onAddPage;
  final ValueChanged<ChurchInfo>? onOpenOutreach;
  final VoidCallback? onAddOutreach;
  final VoidCallback onRetryPages;
  final VoidCallback onRetryStats;

  @override
  Widget build(BuildContext context) {
    context.select((AppContext c) => c.usersEpoch);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final cards = <Widget>[
      if (church.isOutreach && parentChurch != null && onOpenParent != null)
        _ParentChurchCard(
          parent: parentChurch!,
          onOpen: onOpenParent!,
        ),
      _VisitCard(church: church, onOpenMaps: onOpenMaps),
      if (church.hasSocials)
        _SocialsCard(
          socials: church.socials,
          onOpenSocial: onOpenSocial,
        ),
      if (church.hasPastorsSection)
        _PastorsCard(church: church, onLearnAbout: onOpenPastors),
      if (church.isFullChurch &&
          (outreaches.isNotEmpty || (canManageInfo && onAddOutreach != null)))
        _OutreachesCard(
          outreaches: outreaches,
          canAdd: canManageInfo && onAddOutreach != null,
          onOpen: onOpenOutreach,
          onAdd: onAddOutreach,
        ),
      if (church.isFullChurch || church.hasLocation)
        _SnapshotCard(
          church: church,
          stats: stats,
          statsError: statsError,
          onRetryStats: onRetryStats,
        ),
      if (pagesError != null || pages.isNotEmpty || canAddPages)
        _PagesCard(
          pages: pages,
          pagesError: pagesError,
          canAdd: canAddPages,
          onRetry: onRetryPages,
          onOpenPage: onOpenPage,
          onAddPage: onAddPage,
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
          location: church.location,
          visibleLimit: visibleCellGroupLimit,
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
        if (church.isOutreach) ...[
          const SizedBox(height: 4),
          Text(
            l10n.churchHubOutreachBadge,
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
          if (church.hasLocation || church.isFullChurch)
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
            if (church.hasLocation || church.isFullChurch)
              const SizedBox(height: 12),
            Text(
              church.address,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (onOpenMaps != null) ...[
            if (church.hasLocation || church.isFullChurch || church.hasAddress)
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
          if (!church.hasLocation &&
              !church.hasAddress &&
              onOpenMaps == null &&
              church.isOutreach)
            Text(
              l10n.churchHubOutreachFindUsEmpty,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _SocialsCard extends StatelessWidget {
  const _SocialsCard({
    required this.socials,
    this.onOpenSocial,
  });

  final List<ChurchSocialLink> socials;
  final ValueChanged<ChurchSocialLink>? onOpenSocial;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return InfoSectionCard(
      icon: Icons.share_outlined,
      title: l10n.churchHubSocialsTitle,
      subtitle: l10n.churchHubSocialsSubtitle,
      content: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: socials.map((link) {
          final label = ChurchSocialUi.labelFor(l10n, link.platform);
          return Tooltip(
            message: label,
            child: FilledButton.tonalIcon(
              onPressed:
                  onOpenSocial == null ? null : () => onOpenSocial!(link),
              icon: Icon(ChurchSocialUi.iconFor(link.platform)),
              label: Text(label),
              style: FilledButton.styleFrom(
                foregroundColor: colorScheme.onSecondaryContainer,
                backgroundColor:
                    colorScheme.secondaryContainer.withValues(alpha: 0.65),
              ),
            ),
          );
        }).toList(),
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
    final isOutreach = church.isOutreach;

    return InfoSectionCard(
      icon: Icons.groups_outlined,
      title:
          isOutreach ? l10n.churchHubPlantersTitle : l10n.churchHubPastorsTitle,
      subtitle: isOutreach
          ? l10n.churchHubPlantersSubtitle
          : l10n.churchHubPastorsSubtitle,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (church.hasPastorsImage) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AdaptiveInfoGalleryImage(
                imageUrl: church.pastorsImageSrc,
                heroTag: 'info_church_pastors_${church.id}',
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (church.hasPastors)
            ChurchPastorUserList(
              pastorUserIds: church.pastorUserIds,
              unknownLabel: isOutreach
                  ? l10n.churchHubUnknownPlanter
                  : l10n.churchHubUnknownPastor,
            ),
          if (church.hasPastorsBody) ...[
            if (church.hasPastors || church.hasPastorsImage)
              const SizedBox(height: 8),
            FilledButton(
              onPressed: onLearnAbout,
              child: Text(
                isOutreach
                    ? l10n.churchHubLearnAboutPlanters
                    : l10n.churchHubLearnAboutPastors,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ParentChurchCard extends StatelessWidget {
  const _ParentChurchCard({
    required this.parent,
    required this.onOpen,
  });

  final ChurchInfo parent;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return InfoSectionCard(
      icon: Icons.church_outlined,
      title: l10n.churchHubParentChurchTitle,
      subtitle: l10n.churchHubParentChurchSubtitle,
      content: InfoTopicListCard(
        title: parent.title,
        description:
            parent.hasLocation ? parent.location : l10n.churchHubLocationUnset,
        imageUrl: parent.imgSrc,
        heroTag: 'info_church_${parent.id}',
        fallbackIcon: Icons.church_outlined,
        onTap: onOpen,
      ),
    );
  }
}

class _OutreachesCard extends StatelessWidget {
  const _OutreachesCard({
    required this.outreaches,
    required this.canAdd,
    this.onOpen,
    this.onAdd,
  });

  final List<ChurchInfo> outreaches;
  final bool canAdd;
  final ValueChanged<ChurchInfo>? onOpen;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InfoSectionCard(
      icon: Icons.diversity_3_outlined,
      title: l10n.churchHubOutreachesTitle,
      subtitle: l10n.churchHubOutreachesSubtitle,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (outreaches.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                l10n.churchHubNoOutreaches,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            ...outreaches.map(
              (outreach) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InfoTopicListCard(
                  title: outreach.title,
                  description: outreach.summary.isNotEmpty
                      ? outreach.summary
                      : l10n.churchHubOutreachBadge,
                  imageUrl: outreach.imgSrc,
                  heroTag: 'info_church_${outreach.id}',
                  fallbackIcon: Icons.diversity_3_outlined,
                  onTap: () => onOpen?.call(outreach),
                ),
              ),
            ),
          if (canAdd && onAdd != null)
            InfoAddContentCard(
              label: l10n.churchHubAddOutreach,
              description: l10n.churchHubAddOutreachDescription,
              onTap: onAdd!,
            ),
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
    final cellGroupsTile = _HubStatTile(
      icon: Icons.groups_outlined,
      value: '${stats.cellGroupCount}',
      label: l10n.churchHubCellGroupsLabel,
      hint: l10n.churchHubCellGroupsHint,
    );
    final postsTile = _HubStatTile(
      icon: Icons.event_note_outlined,
      value: '${stats.postCount}',
      label: l10n.churchHubPostsLabel,
      hint: l10n.churchHubPostsHint,
    );
    final peopleTile = _HubStatTile(
      icon: Icons.people_outline,
      value: '${stats.peopleCount}',
      label: l10n.churchHubPeopleLabel,
      hint: l10n.churchHubPeopleHint,
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
        cellGroupsTile,
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: postsTile),
            const SizedBox(width: 12),
            Expanded(child: peopleTile),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: colorScheme.primary, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
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
    required this.location,
    required this.visibleLimit,
  });

  final List<CellGroup> groups;
  final bool loading;
  final String location;
  final int visibleLimit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final visible = groups.length > visibleLimit
        ? groups.take(visibleLimit).toList()
        : groups;
    final overflow = groups.length - visible.length;

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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final group in visible)
            _hubCellGroupRow(context, l10n, theme, colorScheme, group),
          if (overflow > 0) ...[
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () => _openLocationGroups(context),
              child: Text(l10n.churchHubViewAllCellGroups(groups.length)),
            ),
          ],
        ],
      );
    }

    return InfoSectionCard(
      icon: Icons.groups_outlined,
      title: l10n.churchHubCellGroupsHere,
      subtitle: l10n.churchHubCellGroupsSubtitle,
      content: content,
    );
  }

  void _openLocationGroups(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CellGroupsAtLocationPage(location: location),
      ),
    );
  }

  Widget _hubCellGroupRow(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    ColorScheme colorScheme,
    CellGroup group,
  ) {
    final cadence = group.cadenceLabel;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          visualDensity: VisualDensity.compact,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          leading: Icon(
            Icons.groups_outlined,
            color: colorScheme.primary,
          ),
          title: Text(
            group.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: cadence.isEmpty
              ? null
              : Text(
                  cadence,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
          trailing: group.isPaused
              ? Text(
                  l10n.cellGroupsStatusPaused,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.tertiary,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : const Icon(Icons.chevron_right),
          onTap: () {
            AppLinks.openCellGroup(context, id: group.id);
          },
        ),
      ),
    );
  }
}
