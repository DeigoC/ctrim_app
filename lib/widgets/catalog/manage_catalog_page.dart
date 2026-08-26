import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../utility/responsive_layout.dart';
import '../common/app_dialog.dart';
import '../common/load_progress_body.dart';
import '../role_access_gate.dart';

/// L10n strings for a catalog manage screen (tags, locations, …).
class ManageCatalogCopy {
  const ManageCatalogCopy({
    required this.title,
    required this.add,
    required this.empty,
    required this.seedDefaults,
    required this.loadingMessage,
    required this.deniedMessage,
    required this.active,
    required this.inactive,
    required this.moveUp,
    required this.moveDown,
    required this.edit,
    required this.activate,
    required this.deactivate,
    required this.delete,
  });

  final String title;
  final String add;
  final String empty;
  final String seedDefaults;
  final String loadingMessage;
  final String deniedMessage;
  final String active;
  final String inactive;
  final String moveUp;
  final String moveDown;
  final String edit;
  final String activate;
  final String deactivate;
  final String delete;
}

/// Shared scaffold for admin catalog lists: role gate, empty/seed, reorder, menu.
class ManageCatalogPage<T> extends StatelessWidget {
  const ManageCatalogPage({
    super.key,
    required this.copy,
    required this.allow,
    required this.loading,
    required this.saving,
    required this.items,
    required this.itemLeading,
    required this.itemName,
    required this.itemIsActive,
    required this.onAdd,
    required this.onSeed,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
    required this.onMove,
  });

  final ManageCatalogCopy copy;
  final bool Function(User user) allow;
  final bool loading;
  final bool saving;
  final List<T> items;
  final Widget Function(T item) itemLeading;
  final String Function(T item) itemName;
  final bool Function(T item) itemIsActive;
  final VoidCallback onAdd;
  final VoidCallback onSeed;
  final void Function(T item) onEdit;
  final void Function(T item) onToggle;
  final void Function(T item) onDelete;
  final void Function(int index, int direction) onMove;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = ResponsiveLayout.isWideScreen(screenWidth);
    final horizontalPadding = isWide
        ? ((screenWidth - ResponsiveLayout.maxContentWidth(screenWidth)) / 2)
            .clamp(0.0, double.infinity)
        : 0.0;

    return RoleAccessGate(
      allow: allow,
      deniedMessage: copy.deniedMessage,
      child: Scaffold(
        appBar: AppBar(
          title: Text(copy.title),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: copy.add,
              onPressed: saving ? null : onAdd,
            ),
          ],
        ),
        body: _buildBody(context, horizontalPadding),
      ),
    );
  }

  Widget _buildBody(BuildContext context, double horizontalPadding) {
    if (loading) {
      return LoadProgressBody(
        message: copy.loadingMessage,
        completedSteps: 0,
        totalSteps: 1,
      );
    }

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(copy.empty, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: saving ? null : onSeed,
                icon: const Icon(Icons.auto_awesome),
                label: Text(copy.seedDefaults),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: saving ? null : onAdd,
                icon: const Icon(Icons.add),
                label: Text(copy.add),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      itemCount: items.length,
      itemBuilder: (_, index) {
        final item = items[index];
        final active = itemIsActive(item);
        return Card(
          child: ListTile(
            leading: itemLeading(item),
            title: Text(itemName(item)),
            subtitle: Text(active ? copy.active : copy.inactive),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_upward),
                  tooltip: copy.moveUp,
                  onPressed:
                      index == 0 || saving ? null : () => onMove(index, -1),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_downward),
                  tooltip: copy.moveDown,
                  onPressed: index == items.length - 1 || saving
                      ? null
                      : () => onMove(index, 1),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit(item);
                      case 'toggle':
                        onToggle(item);
                      case 'delete':
                        onDelete(item);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'edit', child: Text(copy.edit)),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Text(active ? copy.deactivate : copy.activate),
                    ),
                    PopupMenuItem(value: 'delete', child: Text(copy.delete)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class CatalogItemDialogResult {
  const CatalogItemDialogResult({required this.name, this.color});

  final String name;
  final String? color;
}

/// Add/edit dialog for a catalog item. Omit [colorLabel] to hide the color field.
Future<CatalogItemDialogResult?> showCatalogItemDialog({
  required BuildContext context,
  required bool isEditing,
  required String addTitle,
  required String editTitle,
  required String nameLabel,
  required String createLabel,
  required String saveLabel,
  required String cancelLabel,
  String? initialName,
  String? colorLabel,
  String? colorHint,
  String? initialColor,
  IconData addIcon = Icons.add,
}) async {
  final nameController = TextEditingController(text: initialName ?? '');
  final colorController = colorLabel == null
      ? null
      : TextEditingController(text: initialColor ?? '');

  try {
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AppDialog(
          icon: isEditing ? Icons.edit_outlined : addIcon,
          title: isEditing ? editTitle : addTitle,
          actions: AppDialogActions(
            onCancel: () => Navigator.pop(dialogContext),
            cancelLabel: cancelLabel,
            onConfirm: () {
              if (nameController.text.trim().isEmpty) return;
              Navigator.pop(dialogContext, true);
            },
            confirmLabel: isEditing ? saveLabel : createLabel,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: AppDialog.inputDecoration(label: nameLabel),
                autofocus: true,
              ),
              if (colorController != null && colorLabel != null) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: colorController,
                  decoration: AppDialog.inputDecoration(
                    label: colorLabel,
                    hint: colorHint,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );

    if (saved != true) return null;
    final name = nameController.text.trim();
    if (name.isEmpty) return null;
    final color = colorController?.text.trim();
    return CatalogItemDialogResult(
      name: name,
      color: (color == null || color.isEmpty) ? null : color,
    );
  } finally {
    nameController.dispose();
    colorController?.dispose();
  }
}
