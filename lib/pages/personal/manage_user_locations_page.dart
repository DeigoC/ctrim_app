import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../firebase/db_managers/user_location_db_manager.dart';
import '../../models/user_location.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import '../../utility/responsive_layout.dart';
import '../../utility/volunteer_locations.dart';
import '../../widgets/load_progress_body.dart';

class ManageUserLocationsPage extends StatefulWidget {
  const ManageUserLocationsPage({super.key});

  @override
  State<ManageUserLocationsPage> createState() => _ManageUserLocationsPageState();
}

class _ManageUserLocationsPageState extends State<ManageUserLocationsPage> {
  final UserLocationDBManager _locationDBManager = UserLocationDBManager();
  bool _loading = true;
  bool _saving = false;

  static const List<String> _defaultSeedLocations = VolunteerLocations.fallbackAssignable;

  @override
  void initState() {
    super.initState();
    _refreshLocations();
  }

  Future<void> _refreshLocations() async {
    setState(() => _loading = true);
    try {
      final locations = await _locationDBManager.fetchAllLocations();
      if (!mounted) return;
      Provider.of<AppContext>(context, listen: false).setAllLocations(locations);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = ResponsiveLayout.isWideScreen(screenWidth);
    final horizontalPadding = isWide
        ? ((screenWidth - ResponsiveLayout.maxContentWidth(screenWidth)) / 2).clamp(0.0, double.infinity)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.manageUserLocationsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l10n.manageUserLocationsAdd,
            onPressed: _saving ? null : () => _showLocationDialog(),
          ),
        ],
      ),
      body: Consumer<AppContext>(
        builder: (context, appContext, _) {
          if (_loading) {
            return const LoadProgressBody(
              message: 'Loading locations…',
              completedSteps: 0,
              totalSteps: 1,
            );
          }

          final locations = appContext.allLocations;
          if (locations.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding + 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.manageUserLocationsEmpty, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _saving ? null : _seedDefaultLocations,
                      icon: const Icon(Icons.auto_awesome),
                      label: Text(l10n.manageUserLocationsSeedDefaults),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _saving ? null : () => _showLocationDialog(),
                      icon: const Icon(Icons.add),
                      label: Text(l10n.manageUserLocationsAdd),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            itemCount: locations.length,
            itemBuilder: (_, index) {
              final location = locations[index];
              return Card(
                child: ListTile(
                  leading: Icon(
                    Icons.location_on_outlined,
                    color: location.isActive
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  title: Text(location.name),
                  subtitle: Text(
                    location.isActive
                        ? l10n.manageUserLocationsActive
                        : l10n.manageUserLocationsInactive,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_upward),
                        tooltip: l10n.manageUserLocationsMoveUp,
                        onPressed: index == 0 || _saving ? null : () => _moveLocation(index, -1),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_downward),
                        tooltip: l10n.manageUserLocationsMoveDown,
                        onPressed: index == locations.length - 1 || _saving
                            ? null
                            : () => _moveLocation(index, 1),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) => _onMenuAction(location, value),
                        itemBuilder: (_) => [
                          PopupMenuItem(value: 'edit', child: Text(l10n.manageUserLocationsEdit)),
                          PopupMenuItem(
                            value: 'toggle',
                            child: Text(
                              location.isActive
                                  ? l10n.manageUserLocationsDeactivate
                                  : l10n.manageUserLocationsActivate,
                            ),
                          ),
                          PopupMenuItem(value: 'delete', child: Text(l10n.manageUserLocationsDelete)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _onMenuAction(final UserLocation location, final String action) async {
    switch (action) {
      case 'edit':
        await _showLocationDialog(existing: location);
      case 'toggle':
        await _setLocationActive(location, !location.isActive);
      case 'delete':
        await _deleteLocation(location);
    }
  }

  Future<void> _showLocationDialog({UserLocation? existing}) async {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: existing?.name ?? '');
    final isEditing = existing != null;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isEditing ? l10n.manageUserLocationsEdit : l10n.manageUserLocationsAdd),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(labelText: l10n.manageUserLocationsNameLabel),
            autofocus: true,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.cancel)),
            FilledButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) return;
                Navigator.pop(dialogContext, true);
              },
              child: Text(isEditing ? l10n.save : l10n.manageUserLocationsCreate),
            ),
          ],
        );
      },
    );

    if (saved != true || !mounted) {
      nameController.dispose();
      return;
    }

    final name = nameController.text.trim();
    nameController.dispose();

    final appContext = Provider.of<AppContext>(context, listen: false);
    final duplicate = appContext.allLocations.any(
      (l) => l.name.toLowerCase() == name.toLowerCase() && l.id != existing?.id,
    );
    if (duplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.manageUserLocationsDuplicate(name))),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      if (isEditing) {
        final oldName = existing.name;
        await _locationDBManager.renameLocation(location: existing, newName: name);
        appContext.addOrUpdateLocation(existing);
        if (oldName != name) {
          appContext.renameUsersLocation(oldName, name);
        }
      } else {
        final nextOrder = appContext.allLocations.isEmpty
            ? 1
            : appContext.allLocations.map((l) => l.displayOrder).reduce((a, b) => a > b ? a : b) + 1;
        final location = await _locationDBManager.createLocation(
          name: name,
          displayOrder: nextOrder,
        );
        appContext.addOrUpdateLocation(location);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _setLocationActive(final UserLocation location, final bool active) async {
    setState(() => _saving = true);
    try {
      location.setActive(active);
      await _locationDBManager.updateLocation(location);
      if (!mounted) return;
      Provider.of<AppContext>(context, listen: false).addOrUpdateLocation(location);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteLocation(final UserLocation location) async {
    final l10n = AppLocalizations.of(context)!;
    final count = await _locationDBManager.countUsersWithLocation(location.name);
    if (!mounted) return;

    if (count > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.manageUserLocationsDeleteBlocked(count))),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.manageUserLocationsDelete),
        content: Text(l10n.manageUserLocationsDeleteConfirm(location.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.manageUserLocationsDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      await _locationDBManager.deleteLocation(location.id);
      if (!mounted) return;
      Provider.of<AppContext>(context, listen: false).removeLocation(location.id);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _moveLocation(final int index, final int direction) async {
    final appContext = Provider.of<AppContext>(context, listen: false);
    final locations = List<UserLocation>.from(appContext.allLocations);
    final swapIndex = index + direction;
    if (swapIndex < 0 || swapIndex >= locations.length) return;

    final currentOrder = locations[index].displayOrder;
    locations[index].setDisplayOrder(locations[swapIndex].displayOrder);
    locations[swapIndex].setDisplayOrder(currentOrder);

    setState(() => _saving = true);
    try {
      await _locationDBManager.updateLocation(locations[index]);
      await _locationDBManager.updateLocation(locations[swapIndex]);
      appContext.setAllLocations(locations);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _seedDefaultLocations() async {
    setState(() => _saving = true);
    try {
      final appContext = Provider.of<AppContext>(context, listen: false);
      for (var i = 0; i < _defaultSeedLocations.length; i++) {
        final location = await _locationDBManager.createLocation(
          name: _defaultSeedLocations[i],
          displayOrder: i + 1,
        );
        appContext.addOrUpdateLocation(location);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
