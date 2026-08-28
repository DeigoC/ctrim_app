import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../firebase/db_managers/cell_group_db_manager.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import '../../utility/cell_group_activity_stats.dart';
import '../../utility/responsive_layout.dart';
import '../../widgets/media/cached_image_widget.dart';
import '../../widgets/information/info_section_card.dart';

/// Intro / teaching content for Cell Groups (first tab), plus activity snapshot.
class CellGroupsOverviewTab extends StatefulWidget {
  const CellGroupsOverviewTab({super.key});

  /// Same Drive `uc?id=` form as Information → About hardcoded images.
  /// [CachedImageWidget] applies the web CORS proxy and local byte cache.
  static const String _overviewImage =
      'https://drive.google.com/uc?id=1nG1r-fbzkxJxD6qa9jsvcubqCbye2DOS';

  @override
  State<CellGroupsOverviewTab> createState() => _CellGroupsOverviewTabState();
}

class _CellGroupsOverviewTabState extends State<CellGroupsOverviewTab> {
  final CellGroupDBManager _db = CellGroupDBManager();
  CellGroupActivityStats? _stats;
  bool _loadingStats = true;
  Object? _statsError;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _loadingStats = true;
      _statsError = null;
    });
    try {
      final appContext = Provider.of<AppContext>(context, listen: false);
      final cached = appContext.allCellGroups;
      final stats = await _db.fetchActivityStats(
        groups: cached.isEmpty ? null : cached,
      );
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _loadingStats = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statsError = e;
        _loadingStats = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final maxWidth = ResponsiveLayout.maxContentWidth(screenWidth);
        final horizontalPadding =
            screenWidth < ResponsiveLayout.compact ? 16.0 : 32.0;
        final isWideScreen = ResponsiveLayout.isWideScreenOf(context);

        return RefreshIndicator(
          onRefresh: _loadStats,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding, vertical: 16),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colorScheme.primaryContainer,
                            colorScheme.secondaryContainer
                                .withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(Icons.groups,
                              size: 48, color: colorScheme.primary),
                          const SizedBox(height: 16),
                          Text(
                            l10n.cellGroupsOverviewHeadline,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.cellGroupsOverviewIntro,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onPrimaryContainer
                                  .withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    InfoSectionCard(
                      icon: Icons.insights_outlined,
                      title: l10n.cellGroupsActivityTitle,
                      subtitle: l10n.cellGroupsActivitySubtitle,
                      content: _buildActivityContent(context, l10n),
                    ),
                    const SizedBox(height: 24),
                    InfoSectionCard(
                      icon: Icons.menu_book,
                      title: l10n.cellGroupsOverviewVerseTitle,
                      subtitle: l10n.cellGroupsOverviewVerseReference,
                      content: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.outline.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          l10n.cellGroupsOverviewVerseBody,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedImageWidget(
                        imageUrl: CellGroupsOverviewTab._overviewImage,
                        height: isWideScreen ? 250 : 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActivityContent(BuildContext context, AppLocalizations l10n) {
    if (_loadingStats && _stats == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_statsError != null && _stats == null) {
      return Column(
        children: [
          Text(
            l10n.cellGroupsActivityLoadError,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _loadStats,
            icon: const Icon(Icons.refresh),
            label: Text(l10n.cellGroupsActivityRetry),
          ),
        ],
      );
    }

    final stats = _stats ?? CellGroupActivityStats.empty();
    final avgLabel = stats.averagePastAttendance == null
        ? '—'
        : stats.averagePastAttendance!.toStringAsFixed(
            stats.averagePastAttendance! ==
                    stats.averagePastAttendance!.roundToDouble()
                ? 0
                : 1,
          );

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 520;
            final tiles = [
              _StatTile(
                icon: Icons.event_available_outlined,
                value: '${stats.pastMeetingsCount}',
                label: l10n.cellGroupsActivityPastMeetings,
                hint: l10n.cellGroupsActivityPastMeetingsHint,
              ),
              _StatTile(
                icon: Icons.people_outline,
                value: '${stats.pastAttendeesTotal}',
                label: l10n.cellGroupsActivityPastAttendees,
                hint: l10n.cellGroupsActivityPastAttendeesHint,
              ),
              _StatTile(
                icon: Icons.upcoming_outlined,
                value: '${stats.upcomingMeetingsCount}',
                label: l10n.cellGroupsActivityUpcoming,
                hint: l10n.cellGroupsActivityUpcomingHint,
              ),
            ];

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
        ),
        const SizedBox(height: 16),
        Divider(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 420;
            final secondary = <(String, String)>[
              (
                '${stats.activeGroupsCount}',
                l10n.cellGroupsActivityActiveGroupsLabel
              ),
              (
                '${stats.totalActiveMembers}',
                l10n.cellGroupsActivityTotalMembersLabel
              ),
              (
                '${stats.distinctGroupsMetPast}',
                l10n.cellGroupsActivityGroupsMetLabel
              ),
              (avgLabel, l10n.cellGroupsActivityAvgAttendanceLabel),
              if (stats.pausedGroupsCount > 0)
                (
                  '${stats.pausedGroupsCount}',
                  l10n.cellGroupsActivityPausedGroupsLabel
                ),
            ];

            Widget metricAt(int i) => _SecondaryMetric(
                  value: secondary[i].$1,
                  label: secondary[i].$2,
                );

            if (!wide) {
              return Column(
                children: [
                  for (var i = 0; i < secondary.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    metricAt(i),
                  ],
                ],
              );
            }

            final rows = <Widget>[];
            for (var i = 0; i < secondary.length; i += 2) {
              if (i > 0) rows.add(const SizedBox(height: 10));
              if (i + 1 < secondary.length) {
                rows.add(Row(
                  children: [
                    Expanded(child: metricAt(i)),
                    const SizedBox(width: 12),
                    Expanded(child: metricAt(i + 1)),
                  ],
                ));
              } else {
                rows.add(metricAt(i));
              }
            }
            return Column(children: rows);
          },
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
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
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
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

class _SecondaryMetric extends StatelessWidget {
  const _SecondaryMetric({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
