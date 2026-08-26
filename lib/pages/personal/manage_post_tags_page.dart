import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../firebase/db_managers/post_tag_db_manager.dart';
import '../../models/post_tag.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import '../../utility/dialog_manager.dart';
import '../../utility/user_activity_messages.dart';
import '../../utility/user_activity_recorder.dart';
import '../../widgets/manage_catalog_page.dart';
import '../../widgets/post_tag_chip.dart';

class ManagePostTagsPage extends StatefulWidget {
  const ManagePostTagsPage({super.key});

  @override
  State<ManagePostTagsPage> createState() => _ManagePostTagsPageState();
}

class _ManagePostTagsPageState extends State<ManagePostTagsPage> {
  final PostTagDBManager _tagDBManager = PostTagDBManager();
  bool _loading = true;
  bool _saving = false;

  static const List<({String name, String color})> _defaultSeedTags = [
    (name: 'Sunday Worship', color: '#6B4EAA'),
    (name: 'Midweek Service', color: '#3D6B9E'),
    (name: 'Growth Mentoring', color: '#2E7D6F'),
    (name: 'Dawn Watch', color: '#C45B2C'),
    (name: 'Overnight Prayer', color: '#8B5A2B'),
    (name: 'Youth Caregroup', color: '#4A7C59'),
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
      Provider.of<AppContext>(context, listen: false).setAllPostTags(tags);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  ManageCatalogCopy _copy(AppLocalizations l10n) {
    return ManageCatalogCopy(
      title: l10n.managePostTagsTitle,
      add: l10n.managePostTagsAdd,
      empty: l10n.managePostTagsEmpty,
      seedDefaults: l10n.managePostTagsSeedDefaults,
      loadingMessage: 'Loading tags…',
      deniedMessage: 'Only area admins can manage post tags.',
      active: l10n.managePostTagsActive,
      inactive: l10n.managePostTagsInactive,
      moveUp: l10n.managePostTagsMoveUp,
      moveDown: l10n.managePostTagsMoveDown,
      edit: l10n.managePostTagsEdit,
      activate: l10n.managePostTagsActivate,
      deactivate: l10n.managePostTagsDeactivate,
      delete: l10n.managePostTagsDelete,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<AppContext>(
      builder: (context, appContext, _) {
        return ManageCatalogPage<PostTag>(
          copy: _copy(l10n),
          allow: (user) => user.canManageVolunteers,
          loading: _loading,
          saving: _saving,
          items: appContext.allPostTags,
          itemLeading: (tag) => PostTagChip(tag: tag),
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

  Future<void> _showTagDialog({PostTag? existing}) async {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = existing != null;
    final result = await showCatalogItemDialog(
      context: context,
      isEditing: isEditing,
      addTitle: l10n.managePostTagsAdd,
      editTitle: l10n.managePostTagsEdit,
      nameLabel: l10n.managePostTagsNameLabel,
      createLabel: l10n.managePostTagsCreate,
      saveLabel: l10n.save,
      cancelLabel: l10n.cancel,
      initialName: existing?.name,
      colorLabel: l10n.managePostTagsColorLabel,
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
        existing.setStreamKind(null);
        await _tagDBManager.updateTag(existing);
        appContext.addOrUpdatePostTag(existing);
        await UserActivityRecorder().record(
          actorUserId: appContext.currentUser.id,
          log: UserActivityMessages.editedPostTag,
          documentId: existing.id,
        );
      } else {
        final nextOrder = appContext.allPostTags.isEmpty
            ? 1
            : appContext.allPostTags
                    .map((t) => t.displayOrder)
                    .reduce((a, b) => a > b ? a : b) +
                1;
        final tag = await _tagDBManager.createTag(
          name: result.name,
          color: result.color,
          displayOrder: nextOrder,
        );
        appContext.addOrUpdatePostTag(tag);
        await UserActivityRecorder().record(
          actorUserId: appContext.currentUser.id,
          log: UserActivityMessages.createdPostTag,
          documentId: tag.id,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _setTagActive(final PostTag tag, final bool active) async {
    setState(() => _saving = true);
    try {
      tag.setActive(active);
      await _tagDBManager.updateTag(tag);
      if (!mounted) return;
      Provider.of<AppContext>(context, listen: false).addOrUpdatePostTag(tag);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteTag(final PostTag tag) async {
    final l10n = AppLocalizations.of(context)!;
    final count = await _tagDBManager.countPostsWithTag(tag.id);
    if (!mounted) return;

    if (count > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.managePostTagsDeleteBlocked(count))),
      );
      return;
    }

    final confirmed = await DialogManager.showConfirmationDialog(
      context: context,
      title: l10n.managePostTagsDelete,
      content: l10n.managePostTagsDeleteConfirm(tag.name),
      confirmText: l10n.managePostTagsDelete,
      cancelText: l10n.cancel,
      icon: Icons.delete_outline,
      isDestructive: true,
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      await _tagDBManager.deleteTag(tag.id);
      if (!mounted) return;
      Provider.of<AppContext>(context, listen: false).removePostTag(tag.id);
      await UserActivityRecorder().record(
        actorUserId:
            Provider.of<AppContext>(context, listen: false).currentUser.id,
        log: UserActivityMessages.deletedPostTag,
        documentId: tag.id,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _moveTag(final int index, final int direction) async {
    final appContext = Provider.of<AppContext>(context, listen: false);
    final tags = List<PostTag>.from(appContext.allPostTags);
    final swapIndex = index + direction;
    if (swapIndex < 0 || swapIndex >= tags.length) return;

    final currentOrder = tags[index].displayOrder;
    tags[index].setDisplayOrder(tags[swapIndex].displayOrder);
    tags[swapIndex].setDisplayOrder(currentOrder);

    setState(() => _saving = true);
    try {
      await _tagDBManager.updateTag(tags[index]);
      await _tagDBManager.updateTag(tags[swapIndex]);
      appContext.setAllPostTags(tags);
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
        appContext.addOrUpdatePostTag(tag);
        await UserActivityRecorder().record(
          actorUserId: appContext.currentUser.id,
          log: UserActivityMessages.createdPostTag,
          documentId: tag.id,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
