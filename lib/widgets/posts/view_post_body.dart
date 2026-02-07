import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:share_plus/share_plus.dart';
import '../../utility/event_context.dart';
import '../quill_editor_wrapper.dart';

class ViewPostBody extends StatelessWidget {
  const ViewPostBody({super.key, required this.eventContext, required this.updateBody, required this.currentUID});
  final EventContext eventContext;
  final Function updateBody;
  final String currentUID;

  @override
  Widget build(BuildContext context) {
    return _buildBodyWithData(context);
  }

  Widget _buildBodyWithData(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final List<Widget> children = [
      Expanded(
          child: SingleChildScrollView(
              child: Card(
        elevation: 1,
        margin: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with share button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.article_outlined, size: 18, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Text(
                        'Post Content',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  _buildShareButton(context),
                ],
              ),
            ),
            // Content
            QuillViewerWidget(
              jsonContent: eventContext.body,
              padding: const EdgeInsets.all(16.0),
            ),
          ],
        ),
      ))),
    ];

    return SafeArea(top: false, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children));
  }

  Widget _buildShareButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return IconButton.filledTonal(
      onPressed: () => _onShare(context),
      icon: const Icon(Icons.share, size: 18),
      tooltip: 'Save content',
      style: IconButton.styleFrom(
        backgroundColor: colorScheme.surfaceVariant.withOpacity(0.5),
        foregroundColor: colorScheme.onSurfaceVariant,
        padding: const EdgeInsets.all(8),
      ),
      iconSize: 18,
    );
  }

  void _onShare(BuildContext context) async {
    // Prepare share content with title and subtitle
    final StringBuffer shareContent = StringBuffer();
    shareContent.writeln(eventContext.head.title);

    // Add event body content as plain text
    shareContent.writeln('---');
    shareContent.writeln();

    // Convert Quill JSON to plain text
    try {
      final document = quill.Document.fromJson(eventContext.body);
      final plainText = document.toPlainText();
      shareContent.write(plainText.trim());
    } catch (e) {
      // Fallback if conversion fails
      shareContent.write('Unable to extract post content');
    }

    final String finalContent = shareContent.toString();

    if (kIsWeb) {
      // Web: Try native share API, fallback to clipboard
      await _shareOnWeb(context, finalContent);
    } else {
      // Mobile: Use native share sheet with positioning
      final box = context.findRenderObject() as RenderBox?;
      await Share.share(
        finalContent,
        sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
      );
    }
  }

  /// Handle sharing on web platform with fallback
  Future<void> _shareOnWeb(BuildContext context, String content) async {
    try {
      // Try Web Share API first (works on Chrome, Edge, mobile browsers)
      final result = await Share.share(content);

      // If share was dismissed or failed, offer clipboard option
      if (result.status == ShareResultStatus.dismissed || result.status == ShareResultStatus.unavailable) {
        await _showCopyDialog(context, content);
      }
    } catch (e) {
      // Web Share API not supported, show copy dialog
      await _showCopyDialog(context, content);
    }
  }

  /// Show dialog with copy to clipboard option
  Future<void> _showCopyDialog(BuildContext context, String content) async {
    final theme = Theme.of(context);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.share),
        title: const Text('Share Post'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your browser may not support native sharing but you can still copy the content to your clipboard:',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                content,
                style: theme.textTheme.bodySmall,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: content));
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Copied to clipboard!'),
                      ],
                    ),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copy to Clipboard'),
          ),
        ],
      ),
    );
  }
}
