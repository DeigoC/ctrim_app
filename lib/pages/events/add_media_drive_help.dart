import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

const String kGoogleDriveUrl = 'https://drive.google.com';

/// Expandable Google Drive setup help for the add-media URL flow.
class AddMediaDriveHelpSection extends StatelessWidget {
  const AddMediaDriveHelpSection({
    super.key,
    required this.maxImageSizeKB,
    required this.maxVideoSizeMB,
    required this.isVideo,
  });

  final int maxImageSizeKB;
  final int maxVideoSizeMB;
  final bool isVideo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: ExpansionTile(
        leading: Icon(Icons.help_outline, color: colorScheme.primary),
        title: const Text('How to add from Google Drive'),
        subtitle: const Text('Upload, share, and paste your link'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Using Google Drive (recommended)',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          const _AddMediaHelpStep(
            number: 1,
            text:
                'Upload your image or video to Google Drive (drive.google.com or the Drive app).',
          ),
          const _AddMediaHelpStep(
            number: 2,
            text: 'Open the file → Share (or Get link).',
          ),
          const _AddMediaHelpStep(
            number: 3,
            text:
                'Under General access, choose Anyone with the link (Viewer). Copy the link.',
          ),
          _AddMediaHelpStep(
            number: 4,
            text: isVideo
                ? 'Paste the link in the Media URL field above, choose Video, then tap Test & Preview.'
                : 'Paste the link in the Media URL field above, then tap Test & Preview.',
          ),
          const _AddMediaHelpStep(
            number: 5,
            text: 'If the preview looks good, tap Add.',
          ),
          const SizedBox(height: 12),
          Text(
            'Tips',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            '• Images: max $maxImageSizeKB KB · Videos: max $maxVideoSizeMB MB\n'
            '• Google Drive share links are converted to direct links automatically\n'
            '• Direct HTTPS URLs (ending in .jpg, .png, .mp4, etc.) also work\n'
            '• If Test & Preview fails, the file is usually still private — check “Anyone with the link”\n'
            '• For videos, you can add an optional thumbnail URL for a better preview',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: colorScheme.onSurfaceVariant, height: 1.4),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              TextButton.icon(
                onPressed: () => launchUrlString(
                  kGoogleDriveUrl,
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Open Google Drive'),
              ),
              TextButton.icon(
                onPressed: () => launchUrlString(
                  'https://imagecompressor.com',
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Online image compressor'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddMediaHelpStep extends StatelessWidget {
  const _AddMediaHelpStep({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            child: Text('$number', style: theme.textTheme.labelSmall),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
