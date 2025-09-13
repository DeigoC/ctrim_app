import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final List<Widget> children = [
      // Copy button
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _buildShareButton(context, controller.document.toPlainText()),
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

  Widget _buildShareButton(BuildContext context, String plainText) {
    return FilledButton.tonalIcon(
      onPressed: () => _onShare(context, plainText),
      icon: const Icon(Icons.save_alt, size: 16),
      label: const Text('Save Content'),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(fontSize: 12),
      ),
    );
  }

  void _onShare(BuildContext context, String plainText) async {
    final box = context.findRenderObject() as RenderBox?;

    await SharePlus.instance.share(ShareParams(
      text: plainText,
      sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
    ));
  }
}
