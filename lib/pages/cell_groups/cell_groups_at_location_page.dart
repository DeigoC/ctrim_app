import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../firebase/db_managers/cell_group_db_manager.dart';
import '../../models/user.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import '../../utility/cache/refresh_cooldown.dart';
import '../../utility/cell_group_roster_helpers.dart';
import 'cell_groups_list_tab.dart';

/// Groups catalogue filtered to one church / volunteer location.
///
/// Reuses [CellGroupsListTab] from the Cell Groups section.
class CellGroupsAtLocationPage extends StatefulWidget {
  const CellGroupsAtLocationPage({super.key, required this.location});

  final String location;

  @override
  State<CellGroupsAtLocationPage> createState() =>
      _CellGroupsAtLocationPageState();
}

class _CellGroupsAtLocationPageState extends State<CellGroupsAtLocationPage> {
  final CellGroupDBManager _db = CellGroupDBManager();
  bool _loading = true;
  Object? _error;
  Map<String, List<User>> _rosterUsersByGroupId = const {};

  @override
  void initState() {
    super.initState();
    Provider.of<AppContext>(context, listen: false)
        .analytics
        .logCellGroupsAtLocation(widget.location);
    _refresh(ignoreCooldown: true);
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cellGroupsAtLocationTitle(widget.location)),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
      ),
      body: CellGroupsListTab(
        loading: _loading,
        error: _error,
        onRefresh: () => _refresh(),
        onRetry: () => _refresh(ignoreCooldown: true),
        rosterUsersByGroupId: _rosterUsersByGroupId,
        locationFilter: widget.location,
      ),
    );
  }
}
