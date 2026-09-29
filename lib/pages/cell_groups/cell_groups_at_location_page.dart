import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import '../../utility/cache/directory_cache.dart';
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
  bool _loading = true;
  Object? _error;
  Map<String, List<User>> _rosterUsersByGroupId = const {};

  @override
  void initState() {
    super.initState();
    Provider.of<AppContext>(context, listen: false)
        .analytics
        .logCellGroupsAtLocation(widget.location);
    if (Provider.of<AppContext>(context, listen: false)
        .allCellGroups
        .isNotEmpty) {
      _loading = false;
    }
    _refresh();
  }

  Future<void> _refresh({
    bool forceCatalog = false,
    bool ignoreCooldown = false,
  }) async {
    final appContext = Provider.of<AppContext>(context, listen: false);
    if (forceCatalog &&
        !ignoreCooldown &&
        !appContext.sharedPref.canRefreshCellGroups) {
      await Future.delayed(kRefreshCooldownBusyWait);
      return;
    }

    setState(() {
      _loading = appContext.allCellGroups.isEmpty;
      _error = null;
    });
    try {
      if (forceCatalog) {
        await DirectoryCacheCoordinator.instance
            .forceRefreshCellGroups(appContext);
        appContext.sharedPref.setCellGroupsRefreshTime();
      } else if (appContext.allCellGroups.isEmpty) {
        await DirectoryCacheCoordinator.instance.revalidate(
          app: appContext,
          ignoreCooldown: true,
        );
      }

      if (!mounted) return;
      final rosterUsers =
          await CellGroupRosterHelpers.linkedRosterUsersByGroupId(
        groups: appContext.allCellGroups,
        allUsers: appContext.allUsers,
        isGuest: appContext.isCurrentUserGuest,
      );
      if (!mounted) return;
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
        onRefresh: () => _refresh(forceCatalog: true),
        onRetry: () => _refresh(forceCatalog: true, ignoreCooldown: true),
        rosterUsersByGroupId: _rosterUsersByGroupId,
        locationFilter: widget.location,
      ),
    );
  }
}
