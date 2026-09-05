import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/cell_group.dart';
import '../../models/user.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import '../../utility/network_image_helper.dart';
import '../../utility/responsive_layout.dart';
import '../../widgets/common/load_progress_body.dart';
import '../../widgets/my_avatar_stack.dart';
import '../../widgets/paired_row_list.dart';
import 'cell_group_detail_page.dart';

/// Catalogue list of cell groups (second tab).
class CellGroupsListTab extends StatelessWidget {
  const CellGroupsListTab({
    super.key,
    required this.loading,
    required this.error,
    required this.onRefresh,
    this.onRetry,
    this.rosterUsersByGroupId = const {},
  });

  final bool loading;
  final Object? error;
  final Future<void> Function() onRefresh;
  final Future<void> Function()? onRetry;

  /// Linked roster members keyed by cell group id (signed-in only).
  final Map<String, List<User>> rosterUsersByGroupId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    context.select((AppContext c) => (c.catalogsEpoch, c.usersEpoch));
    final appContext = Provider.of<AppContext>(context, listen: false);

    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = constraints.maxWidth;
        final isWideScreen = ResponsiveLayout.isWideScreenOf(context);
        final maxWidth = ResponsiveLayout.maxContentWidth(contentWidth);
        final horizontalPadding = isWideScreen
            ? ((contentWidth - maxWidth) / 2).clamp(16.0, double.infinity)
            : 16.0;

        return RefreshIndicator(
          onRefresh: onRefresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            key: const PageStorageKey<String>('cell_groups_list_tab'),
            slivers: _buildContentSlivers(
              context: context,
              appContext: appContext,
              l10n: l10n,
              isWideScreen: isWideScreen,
              horizontalPadding: horizontalPadding,
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildContentSlivers({
    required BuildContext context,
    required AppContext appContext,
    required AppLocalizations l10n,
    required bool isWideScreen,
    required double horizontalPadding,
  }) {
    if (loading && appContext.allCellGroups.isEmpty) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: LoadProgressBody(
            message: 'Loading cell groups…',
            completedSteps: 0,
            totalSteps: 1,
          ),
        ),
      ];
    }
    if (error != null && appContext.allCellGroups.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: LoadProgressBody(
            message: 'Loading cell groups…',
            completedSteps: 0,
            totalSteps: 1,
            error: error,
            onRetry: () {
              (onRetry ?? onRefresh)();
            },
          ),
        ),
      ];
    }

    final groups =
        appContext.allCellGroups.where((g) => !g.isArchived).toList();
    if (groups.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                l10n.cellGroupsEmpty,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
        ),
      ];
    }

    final isGuest = appContext.isCurrentUserGuest;
    final padding =
        EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 88);

    if (isWideScreen) {
      return [
        SliverPadding(
          padding: padding,
          sliver: SliverToBoxAdapter(
            child: PairedRowList(
              itemCount: groups.length,
              runSpacing: 12,
              itemBuilder: (context, index) => _buildCard(
                appContext: appContext,
                group: groups[index],
                isGuest: isGuest,
              ),
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: padding,
        sliver: SliverList.separated(
          itemCount: groups.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _buildCard(
            appContext: appContext,
            group: groups[index],
            isGuest: isGuest,
          ),
        ),
      ),
    ];
  }

  Widget _buildCard({
    required AppContext appContext,
    required CellGroup group,
    required bool isGuest,
  }) {
    return _CellGroupCard(
      group: group,
      isGuest: isGuest,
      leader: _leaderFor(appContext, group),
      rosterUsers: rosterUsersByGroupId[group.id] ?? const [],
      appDir: appContext.appDir,
    );
  }

  User? _leaderFor(AppContext appContext, CellGroup group) {
    for (final uid in group.leaderUserIds) {
      final match = appContext.allUsers.where((u) => u.id == uid);
      if (match.isNotEmpty) return match.first;
    }
    return null;
  }
}

class _CellGroupCard extends StatelessWidget {
  const _CellGroupCard({
    required this.group,
    required this.isGuest,
    required this.leader,
    required this.rosterUsers,
    required this.appDir,
  });

  final CellGroup group;
  final bool isGuest;
  final User? leader;
  final List<User> rosterUsers;
  final String? appDir;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cadence = group.cadenceLabel;
    final titleLine = group.location.trim().isEmpty
        ? group.name
        : '${group.name} | ${group.location}';

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CellGroupDetailPage(groupId: group.id),
            ),
          );
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stripWidth = (constraints.maxWidth * 0.28).clamp(96.0, 148.0);
            return ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 132),
              child: Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(stripWidth + 14, 14, 14, 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titleLine,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (group.summary.trim().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            group.summary,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.35,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (cadence.isNotEmpty || group.isPaused) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (cadence.isNotEmpty)
                                Text(
                                  cadence,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              if (group.isPaused)
                                Text(
                                  l10n.cellGroupsStatusPaused,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.tertiary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ],
                        if (!isGuest && rosterUsers.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 40,
                            width: double.infinity,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: MyAvatarStack(
                                users: rosterUsers,
                                appDir: appDir,
                              ),
                            ),
                          ),
                        ] else if (!isGuest) ...[
                          const SizedBox(height: 8),
                          Text(
                            l10n.cellGroupsMemberCount(group.memberCount),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: stripWidth,
                    child: _LeaderPhotoStrip(leader: leader),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Tall leading panel (~28% of card) with leader photo or groups placeholder.
class _LeaderPhotoStrip extends StatelessWidget {
  const _LeaderPhotoStrip({required this.leader});

  final User? leader;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = leader;

    if (user != null && user.imgSrc.isNotEmpty) {
      return ColoredBox(
        color: colorScheme.secondaryContainer,
        child: Image.network(
          NetworkImageHelper.getImageUrl(user.imgSrc),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              _placeholder(colorScheme, user.initials),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
            );
          },
        ),
      );
    }

    if (user != null) {
      return _placeholder(colorScheme, user.initials);
    }

    return ColoredBox(
      color: colorScheme.secondaryContainer,
      child: Center(
        child: Icon(
          Icons.groups,
          size: 36,
          color: colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }

  Widget _placeholder(ColorScheme colorScheme, String initials) {
    return ColoredBox(
      color: colorScheme.secondaryContainer,
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSecondaryContainer,
          ),
        ),
      ),
    );
  }
}
