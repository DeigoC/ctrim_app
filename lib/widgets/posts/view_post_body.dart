import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:share_plus/share_plus.dart';
import '../../utility/event_context.dart';

class ViewPostBody extends StatelessWidget {
  const ViewPostBody({super.key, required this.eventContext, required this.updateBody, required this.currentUID});
  final EventContext eventContext;
  final Function updateBody;
  final String currentUID;

  @override
  Widget build(BuildContext context) {
    final quill.QuillController controller = quill.QuillController(
        document: quill.Document.fromJson(eventContext.body), selection: const TextSelection.collapsed(offset: 0));
    return _buildBodyWithData(controller, context);
  }

  Widget _buildBodyWithData(final quill.QuillController controller, final BuildContext context) {
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
                  _buildShareButton(context, eventContext.head.title, controller.document.toPlainText()),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: quill.QuillEditor.basic(
                configurations: quill.QuillEditorConfigurations(
                  controller: controller,
                  sharedConfigurations: quill.QuillSharedConfigurations(
                    locale: const Locale('en'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ))),
    ];

    return SafeArea(top: false, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children));
  }

  Widget _buildShareButton(BuildContext context, String title, String plainText) {
    final colorScheme = Theme.of(context).colorScheme;

    return IconButton.filledTonal(
      onPressed: () => _onShare(context, title, plainText),
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

  void _onShare(BuildContext context, String title, String plainText) async {
    final box = context.findRenderObject() as RenderBox?;

    // Prepend the title to the body text
    final String shareContent = title.isNotEmpty ? '$title\n\n$plainText' : plainText;

    await SharePlus.instance.share(ShareParams(
      text: shareContent,
      sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
    ));
  }
}
