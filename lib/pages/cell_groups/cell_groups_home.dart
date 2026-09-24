import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../firebase/db_managers/cell_group_db_manager.dart';
import '../../models/user.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import '../../utility/cache/refresh_cooldown.dart';
import '../../utility/cell_group_roster_helpers.dart';
import '../../utility/responsive_layout.dart';
import '../../widgets/common/section_tab_bar.dart';
import 'cell_groups_list_tab.dart';
import 'cell_groups_overview_tab.dart';
import 'edit_cell_group_page.dart';

/// Cell Groups section shell: Overview + Groups tabs (same pattern as CTRIM).
class CellGroupsHome extends StatefulWidget {
  const CellGroupsHome({
    super.key,
    required this.tabController,
    this.scrollController,
  });

  static const String _ctrimLogo = 'assets/images/ctrim_logo.png';

  final TabController tabController;
  final ScrollController? scrollController;

  @override
  State<CellGroupsHome> createState() => _CellGroupsHomeState();
}

class _CellGroupsHomeState extends State<CellGroupsHome> {
  final CellGroupDBManager _db = CellGroupDBManager();
  bool _loading = true;
  Object? _error;

  /// Linked roster members per group id (signed-in only; empty for guests).
  Map<String, List<User>> _rosterUsersByGroupId = const {};

  @override
  void initState() {
    super.initState();
    widget.tabController.addListener(_onTabChanged);
    _refresh(ignoreCooldown: true);
  }

  @override
  void dispose() {
    widget.tabController.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _refresh({bool ignoreCooldown = false}) async {
    final appContext = Provider.of<AppContext>(context, listen: false);
    if (!ignoreCooldown && !appContext.sharedPref.canRefreshCellGroups) {
      await Future.delayed(kRefreshCooldownBusyWait);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final groups = await _db.fetchAllGroups();
      if (!mounted) return;
      appContext.setAllCellGroups(groups);

      final rosterUsers =
          await CellGroupRosterHelpers.linkedRosterUsersByGroupId(
        groups: groups,
        allUsers: appContext.allUsers,
        isGuest: appContext.isCurrentUserGuest,
      );
      if (!mounted) return;
      appContext.sharedPref.setCellGroupsRefreshTime();
      setState(() => _rosterUsersByGroupId = rosterUsers);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<({String label, IconData icon})> _sections(AppLocalizations l10n) => [
        (label: l10n.cellGroupsTabOverview, icon: Icons.info_outline),
        (label: l10n.cellGroupsTabGroups, icon: Icons.groups),
      ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appContext = Provider.of<AppContext>(context, listen: false);
    context.select((AppContext c) => c.sessionEpoch);
    final canCreate = appContext.currentUser.canManageCellGroups;
    final onGroupsTab = widget.tabController.index == 1;
    final showTabBar =
        !ResponsiveLayout.isWideScreen(MediaQuery.sizeOf(context).width);

    return Scaffold(
      floatingActionButton: canCreate && onGroupsTab
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: Text(l10n.cellGroupsCreate),
              onPressed: () async {
                final created = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const EditCellGroupPage()),
                );
                if (created == true && mounted) _refresh(ignoreCooldown: true);
              },
            )
          : null,
      body: _buildScrollView(l10n, showTabBar: showTabBar),
    );
  }

  Widget _buildScrollView(AppLocalizations l10n, {required bool showTabBar}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sections = _sections(l10n);

    return NestedScrollView(
      controller: widget.scrollController,
      headerSliverBuilder: (_, __) => [
        SliverAppBar.large(
          title: Text(
            showTabBar
                ? l10n.cellGroupsSectionTitle
                : sections[widget.tabController.index].label,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: false,
          floating: true,
          snap: true,
          backgroundColor: colorScheme.surface,
          surfaceTintColor: colorScheme.surfaceTint,
          leading: showTabBar
              ? Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      CellGroupsHome._ctrimLogo,
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
                )
              : null,
          actions: [
            if (widget.tabController.index == 1)
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loading
                    ? null
                    : () {
                        _refresh();
                      },
              ),
          ],
          bottom: showTabBar
              ? SectionTabBar(
                  controller: widget.tabController,
                  tabs: sections
                      .map((section) => Tab(text: section.label))
                      .toList(),
                )
              : null,
        ),
      ],
      body: TabBarView(
        controller: widget.tabController,
        children: [
          const CellGroupsOverviewTab(),
          CellGroupsListTab(
            loading: _loading,
            error: _error,
            onRefresh: () => _refresh(),
            onRetry: () => _refresh(ignoreCooldown: true),
            rosterUsersByGroupId: _rosterUsersByGroupId,
          ),
        ],
      ),
    );
  }
}
