import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import '../../pages/events/edit_body_page.dart';
import '../../utility/event_context.dart';

class ViewPostBody extends StatefulWidget {
  const ViewPostBody({super.key, required this.eventContext, required this.updateBody, required this.currentUID});
  final EventContext eventContext;
  final Function updateBody;
  final String currentUID;

  @override
  State<ViewPostBody> createState() => _ViewPostBodyState();
}

class _ViewPostBodyState extends State<ViewPostBody> {
  @override
  Widget build(BuildContext context) {
    final quill.QuillController controller = quill.QuillController(
        document: quill.Document.fromJson(widget.eventContext.body),
        selection: const TextSelection.collapsed(offset: 0));
    return _buildBodyWithData(controller, context);
  }

  Widget _buildBodyWithData(final quill.QuillController controller, BuildContext context) {
    final List<Widget> children = [
      Expanded(
          child: SingleChildScrollView(
              child: Padding(
                  padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 16, top: 8),
                  child: quill.QuillEditor.basic(controller: controller, readOnly: true))))
    ];

    if (widget.eventContext.isCurrentUserContributor(widget.currentUID) ||
        widget.eventContext.isCurrentUserAuthor(widget.currentUID)) {
      children.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: ElevatedButton.icon(
              onPressed: () => _onEditBodyClick(context),
              icon: const Icon(Icons.edit),
              label: const Text('Edit Text'))));
    }

    return SafeArea(top: false, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children));
  }

  // * LOGIC
  void _onEditBodyClick(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => EditBodyPage(eventContext: widget.eventContext)))
        .then((_) {
      widget.updateBody();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // how annoying!
        setState(() {});
      });
    });
  }
}
