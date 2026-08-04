import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../firebase/db_managers/user_tag_db_manager.dart';
import '../../models/user_tag.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import '../../utility/responsive_layout.dart';
import '../../widgets/load_progress_body.dart';
import '../../widgets/role_access_gate.dart';
import '../../widgets/user_tag_chip.dart';

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = ResponsiveLayout.isWideScreen(screenWidth);
    final horizontalPadding = isWide
        ? ((screenWidth - ResponsiveLayout.maxContentWidth(screenWidth)) / 2)
            .clamp(0.0, double.infinity)
        : 0.0;

    return RoleAccessGate(
      allow: (user) => user.canManageVolunteers,
      deniedMessage: 'Only area admins can manage user tags.',
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.manageUserTagsTitle),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: l10n.manageUserTagsAdd,
              onPressed: _saving ? null : () => _showTagDialog(),
            ),
          ],
        ),
        body: Consumer<AppContext>(
          builder: (context, appContext, _) {
            if (_loading) {
              return const LoadProgressBody(
                message: 'Loading tags…',
                completedSteps: 0,
                totalSteps: 1,
              );
            }

            final tags = appContext.allTags;
            if (tags.isEmpty) {
              return Center(
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: horizontalPadding + 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l10n.manageUserTagsEmpty,
                          textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _saving ? null : _seedDefaultTags,
                        icon: const Icon(Icons.auto_awesome),
                        label: Text(l10n.manageUserTagsSeedDefaults),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _saving ? null : () => _showTagDialog(),
                        icon: const Icon(Icons.add),
                        label: Text(l10n.manageUserTagsAdd),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              itemCount: tags.length,
              itemBuilder: (_, index) {
                final tag = tags[index];
                return Card(
                  child: ListTile(
                    leading: UserTagChip(tag: tag),
                    title: Text(tag.name),
                    subtitle: Text(tag.isActive
                        ? l10n.manageUserTagsActive
                        : l10n.manageUserTagsInactive),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_upward),
                          tooltip: l10n.manageUserTagsMoveUp,
                          onPressed: index == 0 || _saving
                              ? null
                              : () => _moveTag(index, -1),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_downward),
                          tooltip: l10n.manageUserTagsMoveDown,
                          onPressed: index == tags.length - 1 || _saving
                              ? null
                              : () => _moveTag(index, 1),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) => _onMenuAction(tag, value),
                          itemBuilder: (_) => [
                            PopupMenuItem(
                                value: 'edit',
                                child: Text(l10n.manageUserTagsEdit)),
                            PopupMenuItem(
                              value: 'toggle',
                              child: Text(tag.isActive
                                  ? l10n.manageUserTagsDeactivate
                                  : l10n.manageUserTagsActivate),
                            ),
                            PopupMenuItem(
                                value: 'delete',
                                child: Text(l10n.manageUserTagsDelete)),
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
      ),
    );
  }

  Future<void> _onMenuAction(final UserTag tag, final String action) async {
    switch (action) {
      case 'edit':
        await _showTagDialog(existing: tag);
      case 'toggle':
        await _setTagActive(tag, !tag.isActive);
      case 'delete':
        await _deleteTag(tag);
    }
  }

  Future<void> _showTagDialog({UserTag? existing}) async {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: existing?.name ?? '');
    final colorController = TextEditingController(text: existing?.color ?? '');
    final isEditing = existing != null;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
              isEditing ? l10n.manageUserTagsEdit : l10n.manageUserTagsAdd),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration:
                    InputDecoration(labelText: l10n.manageUserTagsNameLabel),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: colorController,
                decoration: InputDecoration(
                  labelText: l10n.manageUserTagsColorLabel,
                  hintText: '#6B4EAA',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(l10n.cancel)),
            FilledButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) return;
                Navigator.pop(dialogContext, true);
              },
              child: Text(isEditing ? l10n.save : l10n.manageUserTagsCreate),
            ),
          ],
        );
      },
    );

    if (saved != true || !mounted) {
      nameController.dispose();
      colorController.dispose();
      return;
    }

    final name = nameController.text.trim();
    final color = colorController.text.trim();
    nameController.dispose();
    colorController.dispose();

    setState(() => _saving = true);
    try {
      final appContext = Provider.of<AppContext>(context, listen: false);
      if (isEditing) {
        existing.setName(name);
        existing.setColor(color.isEmpty ? null : color);
        await _tagDBManager.updateTag(existing);
        appContext.addOrUpdateTag(existing);
      } else {
        final nextOrder = appContext.allTags.isEmpty
            ? 1
            : appContext.allTags
                    .map((t) => t.displayOrder)
                    .reduce((a, b) => a > b ? a : b) +
                1;
        final tag = await _tagDBManager.createTag(
          name: name,
          color: color.isEmpty ? null : color,
          displayOrder: nextOrder,
        );
        appContext.addOrUpdateTag(tag);
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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.manageUserTagsDelete),
        content: Text(l10n.manageUserTagsDeleteConfirm(tag.name)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.manageUserTagsDelete)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      await _tagDBManager.deleteTag(tag.id);
      if (!mounted) return;
      Provider.of<AppContext>(context, listen: false).removeTag(tag.id);
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
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
