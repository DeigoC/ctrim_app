import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../models/user_tag.dart';
import '../../utility/catalog/user_tag_helpers.dart';
import '../../utility/responsive_layout.dart';
import '../common/app_dialog.dart';
import '../common/load_progress_body.dart';
import '../role_access_gate.dart';
import 'catalog_color_field.dart';

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
    this.itemSubtitle,
    required this.onAdd,
    required this.onSeed,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
    required this.onMove,
    this.itemBanner,
    this.photosLabel,
    this.onPhotos,
  });

  final ManageCatalogCopy copy;
  final bool Function(User user) allow;
  final bool loading;
  final bool saving;
  final List<T> items;
  final Widget Function(T item) itemLeading;
  final String Function(T item) itemName;
  final bool Function(T item) itemIsActive;

  /// Replaces the active/inactive line when the catalogue needs extra status.
  final String Function(T item)? itemSubtitle;
  final VoidCallback onAdd;
  final VoidCallback onSeed;
  final void Function(T item) onEdit;
  final void Function(T item) onToggle;
  final void Function(T item) onDelete;
  final void Function(int index, int direction) onMove;

  /// Optional cover drawn above the list row. Null skips the banner.
  final Widget? Function(T item)? itemBanner;

  /// When both are set, the row menu includes a photos action.
  final String? photosLabel;
  final void Function(T item)? onPhotos;

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
        final banner = itemBanner?.call(item);
        final showPhotos = photosLabel != null && onPhotos != null;
        return Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (banner != null) banner,
              ListTile(
                leading: itemLeading(item),
                title: Text(itemName(item)),
                subtitle: Text(
                  itemSubtitle?.call(item) ??
                      (active ? copy.active : copy.inactive),
                ),
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
                          case 'photos':
                            onPhotos?.call(item);
                          case 'toggle':
                            onToggle(item);
                          case 'delete':
                            onDelete(item);
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'edit', child: Text(copy.edit)),
                        if (showPhotos)
                          PopupMenuItem(
                            value: 'photos',
                            child: Text(photosLabel!),
                          ),
                        PopupMenuItem(
                          value: 'toggle',
                          child: Text(active ? copy.deactivate : copy.activate),
                        ),
                        PopupMenuItem(
                            value: 'delete', child: Text(copy.delete)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class CatalogItemDialogResult {
  const CatalogItemDialogResult({
    required this.name,
    this.color,
    this.visibleToGuests,
    this.description,
    this.imageUrl,
  });

  final String name;
  final String? color;

  /// Set when the dialog showed the guest-visibility switch.
  final bool? visibleToGuests;

  /// Set when the dialog showed the description field. Empty input is null.
  final String? description;

  /// Set when the dialog showed the image URL field. Empty input is null.
  final String? imageUrl;
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
  Iterable<String?> takenColors = const [],
  IconData addIcon = Icons.add,
  String? visibleToGuestsLabel,
  String? visibleToGuestsSubtitle,
  bool initialVisibleToGuests = true,
  String? descriptionLabel,
  String? descriptionHint,
  String? initialDescription,
  int descriptionMaxLength = UserTag.descriptionMaxLength,
  String? imageUrlLabel,
  String? imageUrlHint,
  String? initialImageUrl,
}) async {
  final nameController = TextEditingController(text: initialName ?? '');
  final descriptionController = descriptionLabel == null
      ? null
      : TextEditingController(text: initialDescription ?? '');
  final imageUrlController = imageUrlLabel == null
      ? null
      : TextEditingController(text: initialImageUrl ?? '');
  final colorController = colorLabel == null
      ? null
      : TextEditingController(
          text: UserTagHelpers.normalizeHex(initialColor) ??
              (isEditing
                  ? ''
                  : UserTagHelpers.nextPresetHex(usedHexes: takenColors)),
        );
  var visibleToGuests = initialVisibleToGuests;
  final showGuestSwitch = visibleToGuestsLabel != null;
  final showDescription = descriptionController != null;
  final showImageUrl = imageUrlController != null;

  try {
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                    CatalogColorField(
                      controller: colorController,
                      label: colorLabel,
                      hint: colorHint,
                    ),
                  ],
                  if (showDescription) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController!,
                      minLines: 6,
                      maxLines: null,
                      maxLength: descriptionMaxLength,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: AppDialog.inputDecoration(
                        label: descriptionLabel!,
                        hint: descriptionHint,
                        maxLines: 6,
                      ),
                    ),
                  ],
                  if (showImageUrl) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: imageUrlController!,
                      keyboardType: TextInputType.url,
                      decoration: AppDialog.inputDecoration(
                        label: imageUrlLabel!,
                        hint: imageUrlHint,
                      ),
                    ),
                  ],
                  if (showGuestSwitch) ...[
                    const SizedBox(height: 4),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: visibleToGuests,
                      onChanged: (value) =>
                          setDialogState(() => visibleToGuests = value),
                      title: Text(visibleToGuestsLabel!),
                      subtitle: visibleToGuestsSubtitle == null
                          ? null
                          : Text(visibleToGuestsSubtitle),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );

    if (saved != true) return null;
    final name = nameController.text.trim();
    if (name.isEmpty) return null;
    return CatalogItemDialogResult(
      name: name,
      color: UserTagHelpers.normalizeHex(colorController?.text),
      visibleToGuests: showGuestSwitch ? visibleToGuests : null,
      description:
          showDescription ? _emptyToNull(descriptionController!.text) : null,
      imageUrl: showImageUrl ? _emptyToNull(imageUrlController!.text) : null,
    );
  } finally {
    nameController.dispose();
    descriptionController?.dispose();
    imageUrlController?.dispose();
    colorController?.dispose();
  }
}

String? _emptyToNull(final String raw) {
  final trimmed = raw.trim();
  return trimmed.isEmpty ? null : trimmed;
}
