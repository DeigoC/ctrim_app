import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../firebase/db_managers/user_location_db_manager.dart';
import '../../models/user_location.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import '../../utility/dialog_manager.dart';
import '../../utility/user_activity_messages.dart';
import '../../utility/user_activity_recorder.dart';
import '../../utility/volunteer_locations.dart';
import '../../widgets/manage_catalog_page.dart';

class ManageUserLocationsPage extends StatefulWidget {
  const ManageUserLocationsPage({super.key});

  @override
  State<ManageUserLocationsPage> createState() =>
      _ManageUserLocationsPageState();
}

class _ManageUserLocationsPageState extends State<ManageUserLocationsPage> {
  final UserLocationDBManager _locationDBManager = UserLocationDBManager();
  bool _loading = true;
  bool _saving = false;

  static const List<String> _defaultSeedLocations =
      VolunteerLocations.fallbackAssignable;

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
      Provider.of<AppContext>(context, listen: false)
          .setAllLocations(locations);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  ManageCatalogCopy _copy(AppLocalizations l10n) {
    return ManageCatalogCopy(
      title: l10n.manageUserLocationsTitle,
      add: l10n.manageUserLocationsAdd,
      empty: l10n.manageUserLocationsEmpty,
      seedDefaults: l10n.manageUserLocationsSeedDefaults,
      loadingMessage: 'Loading locations…',
      deniedMessage: 'Only area admins can manage user locations.',
      active: l10n.manageUserLocationsActive,
      inactive: l10n.manageUserLocationsInactive,
      moveUp: l10n.manageUserLocationsMoveUp,
      moveDown: l10n.manageUserLocationsMoveDown,
      edit: l10n.manageUserLocationsEdit,
      activate: l10n.manageUserLocationsActivate,
      deactivate: l10n.manageUserLocationsDeactivate,
      delete: l10n.manageUserLocationsDelete,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Consumer<AppContext>(
      builder: (context, appContext, _) {
        return ManageCatalogPage<UserLocation>(
          copy: _copy(l10n),
          allow: (user) => user.canManageVolunteers,
          loading: _loading,
          saving: _saving,
          items: appContext.allLocations,
          itemLeading: (location) => Icon(
            Icons.location_on_outlined,
            color: location.isActive
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
          itemName: (location) => location.name,
          itemIsActive: (location) => location.isActive,
          onAdd: _showLocationDialog,
          onSeed: _seedDefaultLocations,
          onEdit: (location) => _showLocationDialog(existing: location),
          onToggle: (location) =>
              _setLocationActive(location, !location.isActive),
          onDelete: _deleteLocation,
          onMove: _moveLocation,
        );
      },
    );
  }

  Future<void> _showLocationDialog({UserLocation? existing}) async {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = existing != null;
    final result = await showCatalogItemDialog(
      context: context,
      isEditing: isEditing,
      addTitle: l10n.manageUserLocationsAdd,
      editTitle: l10n.manageUserLocationsEdit,
      nameLabel: l10n.manageUserLocationsNameLabel,
      createLabel: l10n.manageUserLocationsCreate,
      saveLabel: l10n.save,
      cancelLabel: l10n.cancel,
      initialName: existing?.name,
      addIcon: Icons.add_location_alt_outlined,
    );
    if (result == null || !mounted) return;

    final appContext = Provider.of<AppContext>(context, listen: false);
    final duplicate = appContext.allLocations.any(
      (l) =>
          l.name.toLowerCase() == result.name.toLowerCase() &&
          l.id != existing?.id,
    );
    if (duplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.manageUserLocationsDuplicate(result.name))),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      if (existing != null) {
        final oldName = existing.name;
        await _locationDBManager.renameLocation(
            location: existing, newName: result.name);
        appContext.addOrUpdateLocation(existing);
        if (oldName != result.name) {
          appContext.renameUsersLocation(oldName, result.name);
        }
        await UserActivityRecorder().record(
          actorUserId: appContext.currentUser.id,
          log: UserActivityMessages.editedLocation,
          documentId: existing.id,
        );
      } else {
        final nextOrder = appContext.allLocations.isEmpty
            ? 1
            : appContext.allLocations
                    .map((l) => l.displayOrder)
                    .reduce((a, b) => a > b ? a : b) +
                1;
        final location = await _locationDBManager.createLocation(
          name: result.name,
          displayOrder: nextOrder,
        );
        appContext.addOrUpdateLocation(location);
        await UserActivityRecorder().record(
          actorUserId: appContext.currentUser.id,
          log: UserActivityMessages.createdLocation,
          documentId: location.id,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _setLocationActive(
      final UserLocation location, final bool active) async {
    setState(() => _saving = true);
    try {
      location.setActive(active);
      await _locationDBManager.updateLocation(location);
      if (!mounted) return;
      Provider.of<AppContext>(context, listen: false)
          .addOrUpdateLocation(location);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteLocation(final UserLocation location) async {
    final l10n = AppLocalizations.of(context)!;
    final count =
        await _locationDBManager.countUsersWithLocation(location.name);
    if (!mounted) return;

    if (count > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.manageUserLocationsDeleteBlocked(count))),
      );
      return;
    }

    final confirmed = await DialogManager.showConfirmationDialog(
      context: context,
      title: l10n.manageUserLocationsDelete,
      content: l10n.manageUserLocationsDeleteConfirm(location.name),
      confirmText: l10n.manageUserLocationsDelete,
      cancelText: l10n.cancel,
      icon: Icons.delete_outline,
      isDestructive: true,
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      await _locationDBManager.deleteLocation(location.id);
      if (!mounted) return;
      Provider.of<AppContext>(context, listen: false)
          .removeLocation(location.id);
      await UserActivityRecorder().record(
        actorUserId:
            Provider.of<AppContext>(context, listen: false).currentUser.id,
        log: UserActivityMessages.deletedLocation,
        documentId: location.id,
      );
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
        await UserActivityRecorder().record(
          actorUserId: appContext.currentUser.id,
          log: UserActivityMessages.createdLocation,
          documentId: location.id,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
