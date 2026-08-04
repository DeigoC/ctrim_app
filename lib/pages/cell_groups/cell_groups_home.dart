import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../firebase/db_managers/cell_group_db_manager.dart';
import '../../models/cell_group.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import '../../utility/responsive_layout.dart';
import '../../widgets/load_progress_body.dart';
import '../../widgets/responsive_content.dart';
import 'cell_group_detail_page.dart';
import 'edit_cell_group_page.dart';

/// Main Cell Groups section: catalogue list with tiered cards.
class CellGroupsHome extends StatefulWidget {
  const CellGroupsHome({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  State<CellGroupsHome> createState() => _CellGroupsHomeState();
}

class _CellGroupsHomeState extends State<CellGroupsHome> {
  final CellGroupDBManager _db = CellGroupDBManager();
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final groups = await _db.fetchAllGroups();
      if (!mounted) return;
      Provider.of<AppContext>(context, listen: false).setAllCellGroups(groups);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appContext = Provider.of<AppContext>(context);
    final canCreate = appContext.currentUser.canManageCellGroups;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cellGroupsSectionTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _refresh,
          ),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: Text(l10n.cellGroupsCreate),
              onPressed: () async {
                final created = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const EditCellGroupPage()),
                );
                if (created == true && mounted) _refresh();
              },
            )
          : null,
      body: _buildBody(appContext, l10n),
    );
  }

  Widget _buildBody(AppContext appContext, AppLocalizations l10n) {
    if (_loading && appContext.allCellGroups.isEmpty) {
      return const LoadProgressBody(
        message: 'Loading cell groups…',
        completedSteps: 0,
        totalSteps: 1,
      );
    }
    if (_error != null && appContext.allCellGroups.isEmpty) {
      return LoadProgressBody(
        message: 'Loading cell groups…',
        completedSteps: 0,
        totalSteps: 1,
        error: _error,
        onRetry: _refresh,
      );
    }

    final groups = appContext.allCellGroups.where((g) => !g.isArchived).toList();
    if (groups.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.cellGroupsEmpty,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    final width = MediaQuery.sizeOf(context).width;
    final isWide = ResponsiveLayout.isWideScreen(width);
    final isGuest = appContext.isCurrentUserGuest;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ResponsiveContent(
        child: isWide
            ? GridView.builder(
                controller: widget.scrollController,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.4,
                ),
                itemCount: groups.length,
                itemBuilder: (context, index) =>
                    _CellGroupCard(group: groups[index], isGuest: isGuest),
              )
            : ListView.separated(
                controller: widget.scrollController,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                itemCount: groups.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) =>
                    _CellGroupCard(group: groups[index], isGuest: isGuest),
              ),
      ),
    );
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
                child: Icon(Icons.groups, color: theme.colorScheme.onSecondaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      group.name,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
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
