import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../firebase/db_managers/user_tag_db_manager.dart';
import '../../models/user_tag.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import '../../utility/dialog_manager.dart';
import '../../utility/user_activity_messages.dart';
import '../../utility/user_activity_recorder.dart';
import '../../widgets/catalog/manage_catalog_page.dart';
import '../../widgets/catalog/user_tag_chip.dart';

class ManageUserTagsPage extends StatefulWidget {
  const ManageUserTagsPage({super.key});

  @override
  State<ManageUserTagsPage> createState() => _ManageUserTagsPageState();
}

class _ManageUserTagsPageState extends State<ManageUserTagsPage> {
  final UserTagDBManager _tagDBManager = UserTagDBManager();
  bool _loading = true;
  bool _saving = false;

  static const List<({String name, String color})> _defaultSeedTags = [
    (name: 'Worship Team', color: '#6B4EAA'),
    (name: 'Technical', color: '#2E7D6F'),
    (name: 'Speaker', color: '#C45B2C'),
    (name: 'Usher', color: '#3D6B9E'),
  ];

  @override
  void initState() {
    super.initState();
    _refreshTags();
  }

  Future<void> _refreshTags() async {
    setState(() => _loading = true);
    try {
      final tags = await _tagDBManager.fetchAllTags();
      if (!mounted) return;
      Provider.of<AppContext>(context, listen: false).setAllTags(tags);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  ManageCatalogCopy _copy(AppLocalizations l10n) {
    return ManageCatalogCopy(
      title: l10n.manageUserTagsTitle,
      add: l10n.manageUserTagsAdd,
      empty: l10n.manageUserTagsEmpty,
      seedDefaults: l10n.manageUserTagsSeedDefaults,
      loadingMessage: 'Loading tags…',
      deniedMessage: 'Only area admins can manage user tags.',
      active: l10n.manageUserTagsActive,
      inactive: l10n.manageUserTagsInactive,
      moveUp: l10n.manageUserTagsMoveUp,
      moveDown: l10n.manageUserTagsMoveDown,
      edit: l10n.manageUserTagsEdit,
      activate: l10n.manageUserTagsActivate,
      deactivate: l10n.manageUserTagsDeactivate,
      delete: l10n.manageUserTagsDelete,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<AppContext>(
      builder: (context, appContext, _) {
        return ManageCatalogPage<UserTag>(
          copy: _copy(l10n),
          allow: (user) => user.canManageVolunteers,
          loading: _loading,
          saving: _saving,
          items: appContext.allTags,
          itemLeading: (tag) => UserTagChip(tag: tag),
          itemName: (tag) => tag.name,
          itemIsActive: (tag) => tag.isActive,
          onAdd: _showTagDialog,
          onSeed: _seedDefaultTags,
          onEdit: (tag) => _showTagDialog(existing: tag),
          onToggle: (tag) => _setTagActive(tag, !tag.isActive),
          onDelete: _deleteTag,
          onMove: _moveTag,
        );
      },
    );
  }

  Future<void> _showTagDialog({UserTag? existing}) async {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = existing != null;
    final result = await showCatalogItemDialog(
      context: context,
      isEditing: isEditing,
      addTitle: l10n.manageUserTagsAdd,
      editTitle: l10n.manageUserTagsEdit,
      nameLabel: l10n.manageUserTagsNameLabel,
      createLabel: l10n.manageUserTagsCreate,
      saveLabel: l10n.save,
      cancelLabel: l10n.cancel,
      initialName: existing?.name,
      colorLabel: l10n.manageUserTagsColorLabel,
      colorHint: '#6B4EAA',
      initialColor: existing?.color,
    );
    if (result == null || !mounted) return;

    setState(() => _saving = true);
    try {
      final appContext = Provider.of<AppContext>(context, listen: false);
      if (existing != null) {
        existing.setName(result.name);
        existing.setColor(result.color);
        await _tagDBManager.updateTag(existing);
        appContext.addOrUpdateTag(existing);
        await UserActivityRecorder().record(
          actorUserId: appContext.currentUser.id,
          log: UserActivityMessages.editedUserTag,
          documentId: existing.id,
        );
      } else {
        final nextOrder = appContext.allTags.isEmpty
            ? 1
            : appContext.allTags
                    .map((t) => t.displayOrder)
                    .reduce((a, b) => a > b ? a : b) +
                1;
        final tag = await _tagDBManager.createTag(
          name: result.name,
          color: result.color,
          displayOrder: nextOrder,
        );
        appContext.addOrUpdateTag(tag);
        await UserActivityRecorder().record(
          actorUserId: appContext.currentUser.id,
          log: UserActivityMessages.createdUserTag,
          documentId: tag.id,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _setTagActive(final UserTag tag, final bool active) async {
    setState(() => _saving = true);
    try {
      tag.setActive(active);
      await _tagDBManager.updateTag(tag);
      if (!mounted) return;
      Provider.of<AppContext>(context, listen: false).addOrUpdateTag(tag);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteTag(final UserTag tag) async {
    final l10n = AppLocalizations.of(context)!;
    final count = await _tagDBManager.countUsersWithTag(tag.id);
    if (!mounted) return;

    if (count > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.manageUserTagsDeleteBlocked(count))),
      );
      return;
    }

    final confirmed = await DialogManager.showConfirmationDialog(
      context: context,
      title: l10n.manageUserTagsDelete,
      content: l10n.manageUserTagsDeleteConfirm(tag.name),
      confirmText: l10n.manageUserTagsDelete,
      cancelText: l10n.cancel,
      icon: Icons.delete_outline,
      isDestructive: true,
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      await _tagDBManager.deleteTag(tag.id);
      if (!mounted) return;
      Provider.of<AppContext>(context, listen: false).removeTag(tag.id);
      await UserActivityRecorder().record(
        actorUserId:
            Provider.of<AppContext>(context, listen: false).currentUser.id,
        log: UserActivityMessages.deletedUserTag,
        documentId: tag.id,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _moveTag(final int index, final int direction) async {
    final appContext = Provider.of<AppContext>(context, listen: false);
    final tags = List<UserTag>.from(appContext.allTags);
    final swapIndex = index + direction;
    if (swapIndex < 0 || swapIndex >= tags.length) return;

    final currentOrder = tags[index].displayOrder;
    tags[index].setDisplayOrder(tags[swapIndex].displayOrder);
    tags[swapIndex].setDisplayOrder(currentOrder);

    setState(() => _saving = true);
    try {
      await _tagDBManager.updateTag(tags[index]);
      await _tagDBManager.updateTag(tags[swapIndex]);
      appContext.setAllTags(tags);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _seedDefaultTags() async {
    setState(() => _saving = true);
    try {
      final appContext = Provider.of<AppContext>(context, listen: false);
      for (var i = 0; i < _defaultSeedTags.length; i++) {
        final seed = _defaultSeedTags[i];
        final tag = await _tagDBManager.createTag(
          name: seed.name,
          color: seed.color,
          displayOrder: i + 1,
        );
        appContext.addOrUpdateTag(tag);
        await UserActivityRecorder().record(
          actorUserId: appContext.currentUser.id,
          log: UserActivityMessages.createdUserTag,
          documentId: tag.id,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
