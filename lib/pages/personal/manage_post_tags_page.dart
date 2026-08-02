import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../firebase/db_managers/post_tag_db_manager.dart';
import '../../models/post_tag.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import '../../utility/notification_topics.dart';
import '../../utility/responsive_layout.dart';
import '../../widgets/load_progress_body.dart';
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

  static const List<({String name, String color, String streamKind})> _defaultSeedTags = [
    (name: 'Sunday Worship', color: '#6B4EAA', streamKind: NotificationTopics.kindSundayService),
    (name: 'Midweek Service', color: '#3D6B9E', streamKind: NotificationTopics.kindMidweekService),
    (name: 'Growth Mentoring', color: '#2E7D6F', streamKind: NotificationTopics.kindGrowthMentoring),
    (name: 'Dawn Watch', color: '#C45B2C', streamKind: NotificationTopics.kindDawnWatch),
    (name: 'Overnight Prayer', color: '#8B5A2B', streamKind: NotificationTopics.kindOvernightPrayer),
    (name: 'Youth Caregroup', color: '#4A7C59', streamKind: NotificationTopics.kindYouthCaregroup),
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
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = ResponsiveLayout.isWideScreen(screenWidth);
    final horizontalPadding = isWide
        ? ((screenWidth - ResponsiveLayout.maxContentWidth(screenWidth)) / 2).clamp(0.0, double.infinity)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.managePostTagsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l10n.managePostTagsAdd,
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

          final tags = appContext.allPostTags;
          if (tags.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding + 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.managePostTagsEmpty, textAlign: TextAlign.center),
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
                ),
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            itemCount: tags.length,
            itemBuilder: (_, index) {
              final tag = tags[index];
              final streamLabel = tag.isNotifiable
                  ? l10n.managePostTagsStreamKindHint(tag.streamKind!)
                  : l10n.managePostTagsNoStream;
              return Card(
                child: ListTile(
                  leading: PostTagChip(tag: tag),
                  title: Text(tag.name),
                  subtitle: Text(
                    '${tag.isActive ? l10n.managePostTagsActive : l10n.managePostTagsInactive} · $streamLabel',
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_upward),
                        tooltip: l10n.managePostTagsMoveUp,
                        onPressed: index == 0 || _saving ? null : () => _moveTag(index, -1),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_downward),
                        tooltip: l10n.managePostTagsMoveDown,
                        onPressed: index == tags.length - 1 || _saving ? null : () => _moveTag(index, 1),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) => _onMenuAction(tag, value),
                        itemBuilder: (_) => [
                          PopupMenuItem(value: 'edit', child: Text(l10n.managePostTagsEdit)),
                          PopupMenuItem(
                            value: 'toggle',
                            child: Text(tag.isActive ? l10n.managePostTagsDeactivate : l10n.managePostTagsActivate),
                          ),
                          PopupMenuItem(value: 'delete', child: Text(l10n.managePostTagsDelete)),
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

  Future<void> _onMenuAction(final PostTag tag, final String action) async {
    switch (action) {
      case 'edit':
        await _showTagDialog(existing: tag);
      case 'toggle':
        await _setTagActive(tag, !tag.isActive);
      case 'delete':
        await _deleteTag(tag);
    }
  }

  Future<void> _showTagDialog({PostTag? existing}) async {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: existing?.name ?? '');
    final colorController = TextEditingController(text: existing?.color ?? '');
    final streamController = TextEditingController(text: existing?.streamKind ?? '');
    final isEditing = existing != null;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isEditing ? l10n.managePostTagsEdit : l10n.managePostTagsAdd),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: l10n.managePostTagsNameLabel),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: colorController,
                  decoration: InputDecoration(
                    labelText: l10n.managePostTagsColorLabel,
                    hintText: '#6B4EAA',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: streamController,
                  decoration: InputDecoration(
                    labelText: l10n.managePostTagsStreamKindLabel,
                    hintText: 'sunday-service',
                    helperText: l10n.managePostTagsStreamKindHelper,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.cancel)),
            FilledButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) return;
                Navigator.pop(dialogContext, true);
              },
              child: Text(isEditing ? l10n.save : l10n.managePostTagsCreate),
            ),
          ],
        );
      },
    );

    if (saved != true || !mounted) {
      nameController.dispose();
      colorController.dispose();
      streamController.dispose();
      return;
    }

    final name = nameController.text.trim();
    final color = colorController.text.trim();
    final streamKind = streamController.text.trim();
    nameController.dispose();
    colorController.dispose();
    streamController.dispose();

    setState(() => _saving = true);
    try {
      final appContext = Provider.of<AppContext>(context, listen: false);
      if (isEditing) {
        existing.setName(name);
        existing.setColor(color.isEmpty ? null : color);
        existing.setStreamKind(streamKind.isEmpty ? null : streamKind);
        await _tagDBManager.updateTag(existing);
        appContext.addOrUpdatePostTag(existing);
      } else {
        final nextOrder = appContext.allPostTags.isEmpty
            ? 1
            : appContext.allPostTags.map((t) => t.displayOrder).reduce((a, b) => a > b ? a : b) + 1;
        final tag = await _tagDBManager.createTag(
          name: name,
          color: color.isEmpty ? null : color,
          streamKind: streamKind.isEmpty ? null : streamKind,
          displayOrder: nextOrder,
        );
        appContext.addOrUpdatePostTag(tag);
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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.managePostTagsDelete),
        content: Text(l10n.managePostTagsDeleteConfirm(tag.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(l10n.managePostTagsDelete)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      await _tagDBManager.deleteTag(tag.id);
      if (!mounted) return;
      Provider.of<AppContext>(context, listen: false).removePostTag(tag.id);
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
          streamKind: seed.streamKind,
          displayOrder: i + 1,
        );
        appContext.addOrUpdatePostTag(tag);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
