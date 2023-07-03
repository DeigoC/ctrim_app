import 'package:ctrim_app/utility/event_context.dart';
import 'package:flutter/material.dart';

class AddMediaTabBody extends StatefulWidget {
  const AddMediaTabBody({super.key, required this.eventContext});
  final EventContext eventContext;

  @override
  State<AddMediaTabBody> createState() => _AddMediaTabBodyState();
}

class _AddMediaTabBodyState extends State<AddMediaTabBody> {
  @override
  Widget build(BuildContext context) {
    // TODO replace with the order src list!
    final List<String> srcs = widget.eventContext.media.srcTypes.keys.toList();
    return Column(
      children: [
        ElevatedButton.icon(
            onPressed: () {}, icon: const Icon(Icons.add_photo_alternate_rounded), label: const Text('Add Image')),
        ElevatedButton.icon(
            onPressed: () {}, icon: const Icon(Icons.add_photo_alternate_rounded), label: const Text('Add Video')),
        Expanded(
            child: ListView.builder(
                itemCount: srcs.length,
                itemBuilder: (_, index) {
                  return Text('Image / Video box for the src: ${srcs[index]}');
                }))
      ],
    );
  }
}
