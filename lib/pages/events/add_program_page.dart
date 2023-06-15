import 'package:ctrim_app/utility/event_context.dart';
import 'package:flutter/material.dart';

class AddEventProgramPage extends StatefulWidget {
  const AddEventProgramPage({super.key, required this.eventContext});
  final EventContext eventContext;

  @override
  State<AddEventProgramPage> createState() => _AddEventProgramPageState();
}

class _AddEventProgramPageState extends State<AddEventProgramPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Program'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return ListView();
  }
}
