import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/cell_group.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import '../../utility/responsive_layout.dart';
import '../../widgets/load_progress_body.dart';
import 'cell_group_detail_page.dart';

/// Catalogue list of cell groups (second tab).
class CellGroupsListTab extends StatelessWidget {
  const CellGroupsListTab({
    super.key,
    required this.loading,
    required this.error,
    required this.onRefresh,
  });

  final bool loading;
  final Object? error;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appContext = Provider.of<AppContext>(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = constraints.maxWidth;
        final isWideScreen = ResponsiveLayout.isWideScreen(contentWidth);
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
            onRetry: onRefresh,
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
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.4,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) =>
                  _CellGroupCard(group: groups[index], isGuest: isGuest),
              childCount: groups.length,
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
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) =>
              _CellGroupCard(group: groups[index], isGuest: isGuest),
        ),
      ),
    ];
  }
}

class _CellGroupCard extends StatelessWidget {
  const _CellGroupCard({required this.group, required this.isGuest});

  final CellGroup group;
  final bool isGuest;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cadence = group.cadenceLabel;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CellGroupDetailPage(groupId: group.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.secondaryContainer,
                child: Icon(Icons.groups,
                    color: theme.colorScheme.onSecondaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      group.name,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (cadence.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        cadence,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (!isGuest) ...[
                      const SizedBox(height: 2),
                      Text(
                        l10n.cellGroupsMemberCount(group.memberCount),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (group.isPaused) ...[
                      const SizedBox(height: 4),
                      Text(
                        l10n.cellGroupsStatusPaused,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.tertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
