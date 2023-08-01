import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import '../../pages/events/edit_body_page.dart';
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

  Widget _buildBodyWithData(final quill.QuillController controller, BuildContext context) {
    final List<Widget> children = [
      Expanded(
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: quill.QuillEditor.basic(controller: controller, readOnly: true)))
    ];

    if (eventContext.isCurrentUserContributor(currentUID) || eventContext.isCurrentUserAuthor(currentUID)) {
      children.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: ElevatedButton.icon(
              onPressed: () => _onEditBodyClick(context),
              icon: const Icon(Icons.edit),
              label: const Text('Edit Text'))));
    }

    return SafeArea(
      top: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  // * LOGIC
  void _onEditBodyClick(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => EditBodyPage(eventContext: eventContext))).then((_) {
      updateBody();
    });
  }
}
