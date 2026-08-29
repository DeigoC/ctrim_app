import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'add_media_drive_helpers.dart';
import 'add_media_drive_help.dart';

class AddMediaSourceForm extends StatelessWidget {
  const AddMediaSourceForm({
    super.key,
    required this.srcController,
    required this.thumbnailController,
    required this.srcFocusNode,
    required this.isVideo,
    required this.maxImageSizeKB,
    required this.maxVideoSizeMB,
    required this.onSrcChanged,
    required this.onSrcTap,
    required this.onClearSrc,
    required this.onPasteSrc,
    required this.onIsVideoChange,
    required this.onClearThumbnail,
  });

  final TextEditingController srcController;
  final TextEditingController thumbnailController;
  final FocusNode srcFocusNode;
  final bool isVideo;
  final int maxImageSizeKB;
  final int maxVideoSizeMB;
  final ValueChanged<String> onSrcChanged;
  final VoidCallback onSrcTap;
  final VoidCallback onClearSrc;
  final VoidCallback onPasteSrc;
  final ValueChanged<bool> onIsVideoChange;
  final VoidCallback onClearThumbnail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side:
                BorderSide(color: colorScheme.outline.withValues(alpha: 0.12)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.link, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Media source',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap the field to paste a link from your clipboard. Google Drive share links are converted automatically.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => launchUrlString(
                      kGoogleDriveUrl,
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: Icon(Icons.open_in_new, size: 16, color: colorScheme.primary),
                    label: Text(
                      'Open Google Drive',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: srcController,
                  focusNode: srcFocusNode,
                  onChanged: onSrcChanged,
                  onTap: onSrcTap,
                  decoration: InputDecoration(
                    hintText: 'Tap to paste URL from clipboard',
                    label: const Text('Media URL*'),
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(isVideo ? Icons.videocam : Icons.image),
                    suffixIcon: srcController.text.isNotEmpty
                        ? IconButton(
                            onPressed: onClearSrc,
                            icon: const Icon(Icons.clear),
                            tooltip: 'Clear URL',
                          )
                        : IconButton(
                            onPressed: onPasteSrc,
                            icon: const Icon(Icons.content_paste),
                            tooltip: 'Paste from clipboard',
                          ),
                  ),
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 8),
                _AddMediaUrlValidationMessage(url: srcController.text),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side:
                BorderSide(color: colorScheme.outline.withValues(alpha: 0.12)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.category_outlined, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Media type',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _AddMediaTypeOption(
                        icon: Icons.image,
                        label: 'Image',
                        isSelected: !isVideo,
                        onTap: () => onIsVideoChange(false),
                        subtitle: 'Max $maxImageSizeKB KB',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _AddMediaTypeOption(
                        icon: Icons.videocam,
                        label: 'Video',
                        isSelected: isVideo,
                        onTap: () => onIsVideoChange(true),
                        subtitle: 'Max $maxVideoSizeMB MB',
                      ),
                    ),
                  ],
                ),
                if (isVideo) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: thumbnailController,
                    decoration: InputDecoration(
                      hintText: 'https://example.com/thumbnail.jpg',
                      label: const Text('Video Thumbnail URL (Optional)'),
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.image),
                      suffixIcon: thumbnailController.text.isNotEmpty
                          ? IconButton(
                              onPressed: onClearThumbnail,
                              icon: const Icon(Icons.clear),
                              tooltip: 'Clear thumbnail URL',
                            )
                          : null,
                    ),
                    keyboardType: TextInputType.url,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AddMediaTypeOption extends StatelessWidget {
  const _AddMediaTypeOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withValues(alpha: 0.3)
              : Theme.of(context).colorScheme.surface,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddMediaUrlValidationMessage extends StatelessWidget {
  const _AddMediaUrlValidationMessage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.trim().isEmpty) return const SizedBox.shrink();

    final bool isValid = isValidMediaUrl(url);
    final bool isGoogleDrive = driveShareLinkRegExp.hasMatch(url);

    if (isGoogleDrive) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info, color: Colors.blue, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Google Drive link detected - will be automatically converted to direct link',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (!isValid) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error, color: Colors.red, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Please enter a valid URL starting with https://',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red.shade700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
