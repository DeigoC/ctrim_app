import 'package:ctrim_app/utility/event_context.dart';
import 'package:flutter/material.dart';

class EditGallerlyPage extends StatefulWidget {
  const EditGallerlyPage({super.key, required this.eventContext});
  final EventContext eventContext;

  @override
  State<EditGallerlyPage> createState() => _EditGallerlyPageState();
}

class _EditGallerlyPageState extends State<EditGallerlyPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Gallery'),
      ),
    );
  }
}
