import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
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
    final List<Widget> children = [
      // Copy button
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FilledButton.tonalIcon(
              onPressed: () => _copyPostContent(controller, context),
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
      Expanded(
          child: SingleChildScrollView(
              child: Padding(
                  padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 16, top: 0),
                  child: quill.QuillEditor.basic(
                    configurations: quill.QuillEditorConfigurations(controller: controller),
                  )))),
    ];

    return SafeArea(top: false, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children));
  }

  void _copyPostContent(quill.QuillController controller, BuildContext context) {
    // Extract plain text from the QuillController
    final String plainText = controller.document.toPlainText();

    // Copy to clipboard
    Clipboard.setData(ClipboardData(text: plainText));

    // Show confirmation snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Post content copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }
}
