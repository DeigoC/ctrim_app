import 'package:ctrim_app/pages/events/edit_body_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import '../../utility/event_context.dart';

class AddBodyTab extends StatefulWidget {
  const AddBodyTab({super.key, required this.eventContext, required this.onRequiredFieldTextChange});
  final EventContext eventContext;
  final Function(String) onRequiredFieldTextChange;

  @override
  State<AddBodyTab> createState() => _AddBodyTabState();
}

class _AddBodyTabState extends State<AddBodyTab> {
  @override
  Widget build(BuildContext context) {
    final quill.QuillController controller = quill.QuillController(
        document: quill.Document.fromJson(widget.eventContext.body),
        selection: const TextSelection.collapsed(offset: 0));

    return Column(
      children: [
        ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                      context, MaterialPageRoute(builder: (_) => EditBodyPage(eventContext: widget.eventContext)))
                  .then((value) {
                // rebuild for new body
                setState(() {
                  widget.onRequiredFieldTextChange('');
                });
              });
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit Body')),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: quill.QuillEditor.basic(controller: controller, readOnly: true),
        ),
      ],
    );
  }
  //🙏
}
