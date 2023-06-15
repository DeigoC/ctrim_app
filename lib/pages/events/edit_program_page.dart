import 'package:ctrim_app/utility/event_context.dart';
import 'package:flutter/material.dart';

class EditEventProgramPage extends StatefulWidget {
  const EditEventProgramPage({super.key, required this.eventContext});
  final EventContext eventContext;

  @override
  State<EditEventProgramPage> createState() => _EdiEventtProgramPageState();
}

class _EdiEventtProgramPageState extends State<EditEventProgramPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Program'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return ListView();
  }
}
