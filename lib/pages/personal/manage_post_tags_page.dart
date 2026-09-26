import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../firebase/db_managers/post_tag_db_manager.dart';
import '../../models/post_tag.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import '../../utility/catalog/post_tag_helpers.dart';
import '../../utility/dialog_manager.dart';
import '../../utility/network_image_helper.dart';
import '../../utility/responsive_layout.dart';
import '../../utility/user_activity_messages.dart';
import '../../utility/user_activity_recorder.dart';
import '../../widgets/catalog/manage_catalog_page.dart';
import '../../widgets/catalog/post_tag_chip.dart';
import '../../widgets/catalog/user_tag_graphic.dart';
import '../../widgets/common/load_progress_body.dart';
import '../../widgets/responsive_content.dart';
import '../../widgets/role_access_gate.dart';
import '../../widgets/two_column_masonry.dart';
import 'view_post_tag_page.dart';

/// Signed-in catalogue of post tags. Area admins add and edit; everyone else
/// browses active tags and opens each tag's location totals.
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    context.select<AppContext, int>((appContext) => appContext.sessionEpoch);
    context.select<AppContext, int>((appContext) => appContext.catalogsEpoch);
    final appContext = Provider.of<AppContext>(context, listen: false);
    final canManage = appContext.currentUser.canManageVolunteers;
    final tags = PostTagHelpers.browseTags(
      allTags: appContext.allPostTags,
      canManage: canManage,
    );

    return RoleAccessGate(
      allow: (user) => user.id != '0',
      deniedMessage: l10n.postTagsSignedInOnly,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.managePostTagsTitle),
          actions: [
            if (canManage)
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: l10n.managePostTagsAdd,
                onPressed: _saving ? null : () => _showTagDialog(),
              ),
          ],
        ),
        body: _buildBody(context, l10n, tags, canManage),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    List<PostTag> tags,
    bool canManage,
  ) {
    if (_loading) {
      return LoadProgressBody(
        message: l10n.postTagsLoading,
        completedSteps: 0,
        totalSteps: 1,
      );
    }
    if (tags.isEmpty) {
      return _buildEmpty(context, l10n, canManage);
    }

    final isWide = ResponsiveLayout.isWideScreenOf(context);
    final cards = [
      for (var index = 0; index < tags.length; index++)
        _TagCard(
          tag: tags[index],
          canManage: canManage,
          saving: _saving,
          canMoveUp: canManage && index > 0,
          canMoveDown: canManage && index < tags.length - 1,
          onOpen: () => _openTag(tags[index], canManage),
          onEdit: () => _showTagDialog(existing: tags[index]),
          onToggle: () => _setTagActive(tags[index], !tags[index].isActive),
          onDelete: () => _deleteTag(tags[index]),
          onMoveUp: () => _moveTag(index, -1),
          onMoveDown: () => _moveTag(index, 1),
        ),
    ];

    return ResponsiveContent(
      narrowPadding: 16,
      child: isWide
          ? SingleChildScrollView(
              padding: const EdgeInsets.only(top: 16, bottom: 24),
              child: TwoColumnMasonry(children: cards),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: cards.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, index) => cards[index],
            ),
    );
  }

  Widget _buildEmpty(
    BuildContext context,
    AppLocalizations l10n,
    bool canManage,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.style_rounded,
                size: 32,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              canManage ? l10n.managePostTagsEmpty : l10n.postTagsBrowseEmpty,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            if (canManage) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _saving ? null : _seedDefaultTags,
                icon: const Icon(Icons.auto_awesome),
                label: Text(l10n.managePostTagsSeedDefaults),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _saving ? null : () => _showTagDialog(),
                icon: const Icon(Icons.add),
                label: Text(l10n.managePostTagsAdd),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openTag(PostTag tag, bool canManage) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ViewPostTagPage(
          tagId: tag.id,
          onEdit: canManage
              ? () {
                  final current =
                      Provider.of<AppContext>(context, listen: false)
                          .postTagById(tag.id);
                  if (current == null) return;
                  _showTagDialog(existing: current);
                }
              : null,
        ),
      ),
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
      takenColors: Provider.of<AppContext>(context, listen: false)
          .allPostTags
          .map((tag) => tag.color),
      imageUrlLabel: l10n.managePostTagsImageUrlLabel,
      imageUrlHint: l10n.managePostTagsImageUrlHint,
      initialImageUrl: existing?.imageUrl,
    );
    if (result == null || !mounted) return;

    setState(() => _saving = true);
    try {
      final appContext = Provider.of<AppContext>(context, listen: false);
      if (existing != null) {
        existing.setName(result.name);
        existing.setColor(result.color);
        existing.setStreamKind(null);
        existing.setImageUrl(_storedImageUrl(result.imageUrl));
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
          imageUrl: _storedImageUrl(result.imageUrl),
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
    final tags = PostTagHelpers.browseTags(
      allTags: appContext.allPostTags,
      canManage: true,
    );
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

class _TagCard extends StatelessWidget {
  const _TagCard({
    required this.tag,
    required this.canManage,
    required this.saving,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onOpen,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final PostTag tag;
  final bool canManage;
  final bool saving;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final status =
        tag.isActive ? l10n.managePostTagsActive : l10n.managePostTagsInactive;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (tag.imageUrl != null)
              UserTagGraphic(
                imageUrl: tag.imageUrl,
                height: 140,
                borderRadius: 0,
                heroTag: 'post_tag_cover_${tag.id}',
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: PostTagChip(tag: tag),
                        ),
                      ),
                      if (canManage)
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            switch (value) {
                              case 'edit':
                                onEdit();
                              case 'toggle':
                                onToggle();
                              case 'delete':
                                onDelete();
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text(l10n.managePostTagsEdit),
                            ),
                            PopupMenuItem(
                              value: 'toggle',
                              child: Text(tag.isActive
                                  ? l10n.managePostTagsDeactivate
                                  : l10n.managePostTagsActivate),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(l10n.managePostTagsDelete),
                            ),
                          ],
                        ),
                    ],
                  ),
                  if (canManage) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            status,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_upward),
                          tooltip: l10n.managePostTagsMoveUp,
                          onPressed: canMoveUp && !saving ? onMoveUp : null,
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_downward),
                          tooltip: l10n.managePostTagsMoveDown,
                          onPressed: canMoveDown && !saving ? onMoveDown : null,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String? _storedImageUrl(final String? raw) {
  if (raw == null) return null;
  final sanitized = NetworkImageHelper.sanitizeMediaUrl(raw);
  return sanitized.isEmpty ? null : sanitized;
}
