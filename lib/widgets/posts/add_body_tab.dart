import 'package:ctrim_app/pages/events/edit_body_page.dart';
import 'package:flutter/material.dart';
import '../../utility/event_context.dart';
import 'view_post_body.dart';

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
    return Column(
      children: [
        ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                      context, MaterialPageRoute(builder: (_) => EditBodyPage(eventContext: widget.eventContext)))
                  .then((value) {
                setState(() {
                  // rebuild for new body
                  widget.onRequiredFieldTextChange('');
                });
              });
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit Body')),
        ViewPostBody(eventContext: widget.eventContext),
      ],
    );
  }
}
